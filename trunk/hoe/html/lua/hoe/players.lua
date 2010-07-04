
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
-- Create a new player in h.round filled with initial data
--
--------------------------------------------------------------------------------
function create(H)

	local player={}
	
	player.key={kind=H.srv.flavour..".hoe.player."..H.round.id} -- we will not know the key id until after we save
	player.props={}
	
	local p=player.props
		
	p.round_id=H.round.id
	
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
	p.energy=count_ticks( H.round.created , H.srv.time , H.round.timestep )
	
	dat.build_cache(player) -- this just copies the props across
	
-- these are json only vars
	local c=player.cache
	
	c.shout=""

	return check(H,player)
end

--------------------------------------------------------------------------------
--
-- check that a player has initial data and set any missing defaults
--
--------------------------------------------------------------------------------
function check(H,player)

	local c=player.cache
	
	if c.energy < 0                  then c.energy = 0 end
	if c.energy > H.round.max_energy then c.energy = H.round.max_energy end

	return player
end


--------------------------------------------------------------------------------
--
-- Save a player to database
--
-- update the cache, this will copy it into props
--
--------------------------------------------------------------------------------
function put(H,player,t)

	t=t or dat -- use transaction?

	dat.build_props(player)
	local ks=t.put(player)
	
	if ks then
		player.key=dat.keyinfo( ks ) -- update key with new id
	end

	return ks -- return the keystring which is an absolute name
end


--------------------------------------------------------------------------------
--
-- Load a player from database
-- the props will be copies into the cache
--
--------------------------------------------------------------------------------
function get(H,player,t)

	t=t or dat -- use transaction?
	
	if not t.get(player) then return nil end	
	dat.build_cache(player)

	return player
end

--------------------------------------------------------------------------------
--
-- Load a player by id from database
--
--------------------------------------------------------------------------------
function load_id(H,id,t)

	local player=create(H)
	player.key.id=id
	
	return get(H,player,t) -- set to nil on fail to load
end



--------------------------------------------------------------------------------
--
-- create a player in this game for the given user
-- this may fail
-- the player may already exist, we may be trying to join twice simultaneusly
--
--------------------------------------------------------------------------------
function join(H,user)

	for _=1,10 do

		local tu=dat.begin()
		local tp=dat.begin()
		local kp=nil
		local ku=nil
		
		local p=create(H)
		p.cache.email=user.cache.email
		p.cache.name=user.cache.name
		
		if put(H,p,tp) then -- new player put ok
		
			local u=users.get_user(tu,user.cache.email) -- get user
			
			if u then
				local ud=u.cache[H.user_data_name] or {} -- userdata for this round
				u.cache[H.user_data_name]=ud
				
				if ud.player_id then -- already joined?
					tu.rollback()
					tp.rollback()
					return false
				end
				
				ud.player_id=p.key.id -- link the user to this player id for this round
				
				if users.put_user(tu,u) then -- user put ok
					if tu.commit() then
						if tp.commit() then
							return true
						end
					else
						tp.rollback()
					end
				end
			else		
				tu.rollback()
				tp.rollback()
			end
		else
			tu.rollback()
			tp.rollback()
		end
		
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
		kind=H.srv.flavour..".hoe.player."..H.round.id,
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

