
local json=require("json")

local wet_html=require("wetgenes.html")

local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

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

-- manage fights so contains fight logic, try to break stuff down to % which can then
-- be displayed to the user before they decide to try.
-- however the entity manipulated here is more a smart log of interactions than anything else

module("hoe.fights")

--------------------------------------------------------------------------------
--
-- serving flavour can be used to create a subgame of a different flavour
-- make sure we incorporate flavour into the name of our stored data types
--
--------------------------------------------------------------------------------
function kind(H)
	if not H.srv.flavour or H.srv.flavour=="hoe" then return "hoe.fight" end
	return H.srv.flavour..".hoe.fight"
end

--------------------------------------------------------------------------------
--
-- Create a new local fight in H.round filled with initial data
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
		
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache

	return check(H,ent)
end

--------------------------------------------------------------------------------
--
-- check that a fight has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function check(H,ent)

	local ok=true

	local r=H.round.cache
	local c=ent.cache
		
	return ent,ok
end

--------------------------------------------------------------------------------
--
-- Save a fight to database
-- this calls check before putting and does not put if check says it is invalid
-- build_props is called so code should always be updating the cache values
--
--------------------------------------------------------------------------------
function put(H,ent,t)

	t=t or dat -- use transaction?

	local _,ok=check(H,ent) -- check that this is valid to put
	if not ok then return nil end

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
-- Load a fight from database, pass in id or entity
-- the props will be copied into the cache
--
--------------------------------------------------------------------------------
function get(H,id,t)

	local ent=id
	
	if type(ent)~="table" then -- get by id
		ent=create(H)
		ent.key.id=id
	end
	
	t=t or dat -- use transaction?
	
	if not t.get(ent) then return nil end	
	dat.build_cache(ent)
	
	return check(H,ent)
end

--------------------------------------------------------------------------------
--
-- change a fight by a table, each value present is set
--
--------------------------------------------------------------------------------
function update_set(H,id,by)

	local f=function(H,p)
		for i,v in pairs(by) do
			p[i]=v
		end
		return true
	end		
	return update(H,id,f)	
end

--------------------------------------------------------------------------------
--
-- get - update - put
--
-- f must be a function that changes the trade.cache and returns true on success
-- id can be an id or an entity from which we will get the id
--
--------------------------------------------------------------------------------
function update(H,id,f)

	if type(id)=="table" then id=id.key.id end -- can turn an entity into an id
		
	for retry=1,10 do
		local mc={}
		local t=dat.begin()
		local e=get(H,id,t)
		if e then
			what_memcache(H,e,mc) -- the original values
			if not f(H,e.cache) then return false end -- hard fail
			check(H,e) -- keep consistant
			if put(H,e,t) then -- entity put ok
				if t.commit() then -- success
					what_memcache(H,e,mc) -- the new values
					fix_memcache(H,mc) -- change any memcached values we just adjusted
					return e -- return the adjusted entity
				end
			end
		end
		t.rollback() -- undo everything ready to try again
	end
	
end


--------------------------------------------------------------------------------
--
-- given an entity return or update a list of cache keys we should recalculate
-- this list is a name->bool lookup
--
--------------------------------------------------------------------------------
function what_memcache(H,ent,mc)
	local mc=mc or {} -- can supply your own result table for merges	
	local c=ent.cache
	
	return mc
end

--------------------------------------------------------------------------------
--
-- fix the memcache items previously produced by what_memcache
-- probably best just to delete them so they will automatically get rebuilt
--
--------------------------------------------------------------------------------
function fix_memcache(H,mc)
	for n,b in pairs(mc) do
		cache.del(n)
	end
end


--------------------------------------------------------------------------------
--
-- create a robbery, nothing is written to the databse it just works out fight data locally
--
-- a robbery is an attempt to steal money from a player
--
--------------------------------------------------------------------------------
function create_robbery(H,p1,p2)

	local ent=create(H)
	local c=ent.cache

	c.energy=math.ceil(p1.cache.bros/1000) -- costs 1 energy per 1000 bros to rob
	
	c.sides={ {player=p1.cache} , {player=p2.cache} } -- the sides involved [1] is attacker and [2] is defender
	
	for i=1,#c.sides do local v=c.sides[i]
		v.win={} -- the change if the attacker wins
		v.los={} -- the change if the attacker loses
		v.bros_min=math.ceil(v.player.bros/v.player.houses) -- minimum bros involved, houses spread out your bros
		v.bros_max=v.player.bros -- maximum bros involved
		v.bros=math.random(v.bros_min,v.bros_max) -- randomised number of bros involved in this fight
		v.sticks=v.bros -- every bro gets a stick
		if v.bros>v.player.sticks then v.sticks=v.player.sticks end -- unless there are not enough sticks
		v.power=v.bros+v.sticks -- total fighting power
	end
	
	local att=c.sides[1]
	local def=c.sides[2]
	
	local function winchance(pow1,pow2) -- given two power values return chance of pow1 winning as a percentage
		local best=90
		if (pow1<=0) or pow1 <= (pow2*0.5) then return 0 end -- no chance of winning
		if (pow2<=0) or pow1 >= (pow2*4.5) then return best end -- best chance of winning
		
		local p=pow1-(pow2*0.5) -- if the attacker has half the power of the defender, they stand a chance
		p=p/(pow2*(4.5-0.5)) -- their chance increase until they have about 4.5x the power of the defender
		p=math.floor(100*p)
		
		if p<1    then p=0    end
		if p>best then p=best end
	
		return p
	end
	
	 -- the user sees this number, which is an average
	c.display_percent=winchance(att.bros_min+att.bros_max,def.bros_min+def.bros_max)
	
	c.percent=winchance(att.power,def.power) -- this is the real chance of attacker winning (randomised)

	c.win={}
	c.los={}
	
	local frand=function(min,max,div) return math.random(min,max)/div end

-- win 
	c.win.bux     = math.floor(def.player.bux*frand(5,15,100))		-- att gains 5%->15% bux from def
	att.win.bros  =-math.floor(att.bros      *frand(0,200,10000))	-- att loses 0%->2% of bros
	att.win.sticks=-math.floor(att.sticks    *frand(0,100,100))		-- att loses 0%->100% of sticks
	def.win.bros  =-math.floor(def.bros      *frand(0,100,10000))	-- def loses 0%->1% of bros
	def.win.sticks=-math.floor(def.sticks    *frand(0,100,100))		-- def loses 0%->100% of sticks
	
--lose
	att.los.bros  =-math.floor(att.bros      *frand(0,500,10000))	-- att loses 0%->5% of bros
	att.los.sticks=-math.floor(att.sticks    *frand(0,100,100))		-- att loses 0%->100% of sticks
	
	return ent
	
end
