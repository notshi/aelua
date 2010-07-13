
local Json=require("Json")

local wet_html=require("wetgenes.html")

local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html  =require("hoe.html")
local rounds=require("hoe.rounds")



local math=math
local string=string
local table=table

local ipairs=ipairs
local pairs=pairs
local tostring=tostring
local tonumber=tonumber
local type=type

-- manage players



module("hoe.players")

--------------------------------------------------------------------------------
--
-- serving flavour can be used to create a subgame of a differnt flavour
-- make sure we incorporate flavour into the name of our stored data types
--
--------------------------------------------------------------------------------
function kind(H)
	if not H.srv.flavour or H.srv.flavour=="hoe" then return "hoe.player" end
	return H.srv.flavour..".hoe.player"
end

--------------------------------------------------------------------------------
--
-- Create a new local player in H.round filled with initial data
--
--------------------------------------------------------------------------------
function create(H)

	local ent={}
	
	ent.key={kind=kind(H)} -- we will not know the key id until after we save
	ent.props={}
	
	local p=ent.props
		
	p.round_id=H.round.key.id
	
	p.created=H.srv.time
	p.updated=H.srv.time
	
	p.score=0
	p.energy=0
	p.bux=0
	p.houses=1
	p.hoes=0
	p.bros=0
	p.gloves=100
	p.sticks=0
	p.manure=0
	p.oil=0
	
	p.name="anon"
	p.email=""
	
-- at the start of the game, a players energy fills up, so there is no disadvantage to slightly late starters 
-- after a short period of time (about 2 days for standard games) everyone begins with max energy
	p.energy=count_ticks( H.round.cache.created , H.srv.time , H.round.cache.timestep )
	
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache
	
	c.shout=""

	return check(H,ent)
end

--------------------------------------------------------------------------------
--
-- check that a player has initial data and set any missing defaults
--
--------------------------------------------------------------------------------
function check(H,ent)

	local r=H.round.cache
	local c=ent.cache
	
	local ticks=count_ticks( c.updated , H.srv.time , r.timestep ) -- ticks since player was last updated
	c.updated=H.srv.time
	
	if ticks>0 then -- hand out energy over time
		c.energy=c.energy+ticks
	end

	if c.energy < 0            then c.energy = 0 end -- sanity
	if c.energy > r.max_energy then c.energy = r.max_energy end -- cap energy to maximum

-- score can be rebuilt from all other values
	
	c.score= ( c.houses * 50000 ) + ( c.hoes * 1000 ) + ( c.bros * 100 ) + ( c.bux ) + ( c.manure )

	return ent
end


--------------------------------------------------------------------------------
--
-- Save a player to database
--
-- update the cache, this will copy it into props
--
--------------------------------------------------------------------------------
function put(H,ent,t)

	t=t or dat -- use transaction?

	dat.build_props(ent)
	local ks=t.put(ent)
	
	if ks then
		ent.key=dat.keyinfo( ks ) -- update key with new id
		dat.build_cache(ent)
	end

	return ks -- return the keystring which is an absolute name
end


--------------------------------------------------------------------------------
--
-- Load a player from database
-- the props will be copied into the cache
--
--------------------------------------------------------------------------------
function get(H,ent,t)

	t=t or dat -- use transaction?
	
	if not t.get(ent) then return nil end	
	dat.build_cache(ent)
	
	return check(H,ent)
end

--------------------------------------------------------------------------------
--
-- Load a player by id from database
--
--------------------------------------------------------------------------------
function get_id(H,id,t)

	local ent=create(H)
	ent.key.id=id
	
	return get(H,ent,t) -- set to nil on fail to load
end



--------------------------------------------------------------------------------
--
-- create a player in this game for the given user
-- this may fail
-- the player may already exist
-- we may be trying to join twice simultaneusly
-- but it will probably work
--
--------------------------------------------------------------------------------
function join(H,user)

	for retry=1,10 do

		local tu=dat.begin()
		local tp=dat.begin()
		local kp=nil
		local ku=nil
		
		local p=create(H)
		p.cache.email=user.cache.email
		p.cache.name=user.cache.name
		
		if put(H,p,tp) then -- new player put ok
		
			local u=users.get_user(user.cache.email,tu) -- get user
			
			if u then
				local ud=u.cache[H.user_data_name] or {} -- userdata for this round
				u.cache[H.user_data_name]=ud
				
				-- this bit deals with the fact that we have two transactions and that
				-- tu may get commited then tp might fail
				if ud.player_id then -- already joined?
					p=get_id(H,ud.player_id) -- does the player exist? (no transaction needed)
					if p and p.cache.email==user.cache.email then -- check that link to player is good
						tu.rollback()
						tp.rollback()
						return false
					end
				end
				
				ud.player_id=p.key.id -- link the user to this player id for this round
				
				if users.put_user(u,tu) then -- user put ok?
				
					if tu.commit() then -- commit the pointer first, pointers can be updated later
						if tp.commit() then -- failure means tu was commited but tp was not
							rounds.inc_players(H,H.round.key.id) -- adjust round player count +1
							return true
						end
					end
				end
			end
		end
		
		tu.rollback() -- try and undo everything ready to try again
		tp.rollback()
	end
	
	return false
end

--------------------------------------------------------------------------------
--
-- Load a list of players from database
--
--------------------------------------------------------------------------------
function list(H,opts,t)

	t=t or dat -- use transaction?
	
	local r=t.query({
		kind=kind(H),
		limit=10,
		offset=0,
			{"filter","round_id","==",H.round.key.id},
			{"sort","score","DESC"},
		})
		
	for i=1,#r do local v=r[i]
		dat.build_cache(v)
	end

	return r
end

--------------------------------------------------------------------------------
--
-- turn two time stamps and a period into a number that represents the number of
-- periods experienced in that time, such that we can run any number of sequential
-- periods and end up with the same number of ticks
--
--------------------------------------------------------------------------------
function count_ticks(from,stop,step)

	local from=math.floor(from/step)
	local stop=math.floor(stop/step)

	return stop-from
end

--------------------------------------------------------------------------------
--
-- adjust a player by a table or a function
--
--------------------------------------------------------------------------------
function adjust(H,id,by)

	local f=function(H,p)
		if by.energy and by.energy<0 then
			if p.energy<(-by.energy) then -- not enough energy to perform
				return false
			end
		end
		if by.bux and by.bux<0 then
			if p.bux<(-by.bux) then -- not enough bux to perform
				return false
			end
		end
		for i,v in pairs(by) do
			if type(v)=="number" then -- add it
				p[i]=(p[i] or 0)+v
				if p[i]<0 then p[i]=0 end -- not allowed to go bellow 0
			else -- just set it
				p[i]=v
			end
		end
		return true
	end

	if type(id)=="table" then id=id.key.id end -- can turn a player into an id
	if type(by)=="function" then f=func end -- more control
		
	for retry=1,10 do
		local t=dat.begin()
		local p=get_id(H,id,t)
		if p then
			if not f(H,p.cache) then return false end -- hard fail, possibly due to lack of energy
			check(H,p) -- also update the score
			if put(H,p,t) then -- player put ok
				if t.commit() then -- success
					return p -- return the adjusted player
				end
			end
		end
		t.rollback() -- undo everything ready to try again
	end
	
end

