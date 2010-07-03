
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

	local p={}
	
	p.id=0
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
	
	p.shout=""
	p.name="anon"
	p.email=""
	
-- at the start of the game, a players energy fills up, so there is no disadvantage to slightly late starters 
-- after a short period of time (about 2 days for standard games) everyone begins with max energy
	p.energy=count_ticks( H.round.created , H.srv.time , H.round.timestep )
	
	p.ent={key={kind=H.srv.flavour..".hoe.player."..H.round.id}} -- we will not know the key id until after we save

	return check(H,p)
end

--------------------------------------------------------------------------------
--
-- check that a player has initial data and set any missing defaults
--
--------------------------------------------------------------------------------
function check(H,player)

	local p=player
	
	if p.energy < 0                  then p.energy = 0 end
	if p.energy > H.round.max_energy then p.energy = H.round.max_energy end
	
	
	
	return p
end

--------------------------------------------------------------------------------
--
-- Convert player data into an entity
--
--------------------------------------------------------------------------------
function to_ent(H,player,ent)

	local p=player
	
	local dat={
		shout=p.shout
		}
	ent.props={
		name=p.name,
		email=p.email,
		json=Json.Encode(dat),
		updated=H.srv.time,
		created=p.created,
		round_id=p.round_id,
		score=p.score,
		energy=p.energy,
		bux=p.bux,
		houses=p.houses,
		hoes=p.hoes,
		scarecrows=p.scarecrows,
		gloves=p.gloves,
		sticks=p.sticks,
		manure=p.manure,
		oil=p.oil,
		}
		
	return ent	
end

--------------------------------------------------------------------------------
--
-- Convert an entity into round data
--
--------------------------------------------------------------------------------
function from_ent(H,player,ent)

	local c=ent.cache
	local p=player
	
	p.id=ent.key.id
	
	p.round_id=c.round_id
	
	p.created=c.created
	p.updated=c.updated
	
	p.score		=c.score
	p.energy	=c.energy
	p.bux		=c.bux
	p.houses	=c.houses
	p.hoes		=c.hoes
	p.scarecrows=c.scarecrows
	p.gloves	=c.gloves
	p.sticks	=c.sticks
	p.manure	=c.manure
	p.oil		=c.oil
	
	check(H,p)
	
	return p
end


--------------------------------------------------------------------------------
--
-- Save a player to database
--
--------------------------------------------------------------------------------
function save(H,player)

	to_ent(H,player,player.ent)
	
	local ks=dat.put(player.ent)
	player.ent.key=dat.keyinfo( ks )
	player.id=player.ent.key.id

	return ks -- return the keystring which is an absolute name
end


--------------------------------------------------------------------------------
--
-- Load a player from database
--
--------------------------------------------------------------------------------
function load(H,player)

	if not dat.get(player.ent) then return nil end
	
	dat.build_cache(player.ent)
	from_ent(H,player,player.ent)

	return player
end

--------------------------------------------------------------------------------
--
-- Load a player by id from database
--
--------------------------------------------------------------------------------
function load_id(H,id)

	local player=create(H)
	player.ent.key.id=id
	player=load(H,player) -- set to nil on fail to load
	return player
end



--------------------------------------------------------------------------------
--
-- create a player in this game for the given user
-- this may fail
-- the player may already exist, we may be trying to join twice simultaneusly
--
--------------------------------------------------------------------------------
function join(H,user)
end

--------------------------------------------------------------------------------
--
-- Load a list of players from database
--
--------------------------------------------------------------------------------
function list(H,opts)

	local list={}
	
	local t=dat.query({
		kind=H.srv.flavour..".hoe.player."..H.round.id,
		limit=10,
		offset=0,
			{"sort","updated","<"},
		})
		
	for i=1,#t do local v=t[i]
		
		list[i]=create(H)
		list[i].ent=dat.build_cache(v)
		from_ent(H,list[i],list[i].ent)
	end

	return list
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

