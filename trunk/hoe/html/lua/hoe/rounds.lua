
local wet_html=require("wetgenes.html")
local Json=require("Json")

local dat=require("wetgenes.aelua.data")

local user=require("wetgenes.aelua.user")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html  =require("hoe.html")


local math=math
local string=string
local table=table

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type

-- manage rounds
-- not only may there be many rounds active at once
-- information may still be requested about rounds that have finished

module("hoe.rounds")


--------------------------------------------------------------------------------
--
-- Create a new round filled with initial data
--
--------------------------------------------------------------------------------
function create(H)

	local r={}
	
	r.id=0
	
	r.created=H.srv.time
	r.updated=H.srv.time
	
	r.timestep=1 -- 60*10 -- a 10 minute tick, gives 144 ticks a day
	
	r.endtime=H.srv.time+(r.timestep*4032) -- default game end after about a month of standard ticks
	-- setting the tick to 1 second gets us the same amount of game time in about 1 hour
	
	r.max_energy=300	-- maximum amount of energy a player can have at once
						-- energy never, under any cirumstances goes over this number
	
	r.state="active" -- a new round starts as active
	
	
	r.ent={key={kind=H.srv.flavour..".hoe.round"}} -- we will not know the key id until we save

	return check(H,r)
end

--------------------------------------------------------------------------------
--
-- check that a round has initial data and set any missing defaults
-- this function handles live updates to old data read from database
-- use the created or updated time stamp as version test if really necesary
-- but it is better to just look at what data is available rather than version test
--
--------------------------------------------------------------------------------
function check(H,round)

	local r=round
	
	
	return r
end

--------------------------------------------------------------------------------
--
-- Convert round data into an entity
--
--------------------------------------------------------------------------------
function to_ent(H,round,ent)
	
	local dat={
		}
	ent.props={
		json=Json.Encode(dat),
		updated=H.srv.time,
		created=round.created,
		timestep=round.timestep,
		endtime=round.endtime,
		state=round.state,
		}
		
	return ent	
end

--------------------------------------------------------------------------------
--
-- Convert an entity into round data
--
--------------------------------------------------------------------------------
function from_ent(H,round,ent)

	local c=ent.cache
	local r=round
	
	r.id=ent.key.id
	
	r.state=c.state
	
	r.created=c.created
	r.updated=c.updated
	
	r.timestep=c.timestep
	r.endtime=c.endtime
	
	check(H,r)
	
	return r
end


--------------------------------------------------------------------------------
--
-- Save a round to database
--
--------------------------------------------------------------------------------
function save(H,round)

	to_ent(H,round,round.ent)
	
	local ks=dat.put(round.ent)
	round.ent.key=dat.keyinfo( ks )
	round.id=round.ent.key.id

	return ks -- return the keystring which is an absolute name
end


--------------------------------------------------------------------------------
--
-- Load a round from database
--
--------------------------------------------------------------------------------
function load(H,round)

	if not dat.get(round.ent) then return nil end
	
	dat.build_cache(round.ent)
	from_ent(H,round,round.ent)

	return round
end

--------------------------------------------------------------------------------
--
-- Load a round id from database
--
--------------------------------------------------------------------------------
function load_id(H,id)

	local round=create(H)
	round.ent.key.id=id
	round=load(H,round) -- set to nil on fail to load
	return round
end
--------------------------------------------------------------------------------
--
-- Load a list of rounds from database
--
--------------------------------------------------------------------------------
function list(H,opts)

	local list={}
	
	local t=dat.query({
		kind=H.srv.flavour..".hoe.round",
		limit=10,
		offset=0,
			{"filter","state","==","active"},
			{"sort","updated","<"},
		})
		
	for i=1,#t do local v=t[i]
		
		list[i]=create(H)
		list[i].ent=dat.build_cache(v)
		from_ent(H,list[i],list[i].ent)
	end

	return list
end

