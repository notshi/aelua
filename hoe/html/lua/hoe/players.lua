
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
local tostring=tostring
local tonumber=tonumber
local type=type

-- manage players



module("hoe.players")


--------------------------------------------------------------------------------
--
-- Create a new local player in H.round filled with initial data
--
--------------------------------------------------------------------------------
function create(H)

	local ent={}
	
	ent.key={kind=H.srv.flavour..".hoe.player."..H.round.key.id} -- we will not know the key id until after we save
	ent.props={}
	
	local p=ent.props
		
	p.round_id=H.round.key.id
	
	p.created=H.srv.time
	p.updated=H.srv.time
	
	p.score=0
	p.energy=0
	p.bux=0
	p.houses=0
	p.hoes=0
	p.scarecrows=0
	p.gloves=0
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
-- the props will be copies into the cache
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
					p=get_id(H,ud.player_id)
					if p and p.cache.email==user.cache.email then -- check that link to player is good
						tu.rollback()
						tp.rollback()
						return false
					end
				end
				
				ud.player_id=p.key.id -- link the user to this player id for this round
				
				if users.put_user(u,tu) then -- user put ok?
				
					if tu.commit() then -- commit the pointer first, pointers can be updated later
						if tp.commit() then return true end -- failure means tu was commited but tp was not
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
		kind=H.srv.flavour..".hoe.player."..H.round.key.id,
		limit=10,
		offset=0,
			{"sort","updated","DESC"},
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

