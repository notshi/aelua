
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
local setmetatable=setmetatable

-- lists of important activities
-- mostly displayed in user profiles
-- sometimes msgs from the other player are also stored
-- when an activity is for two players, two entities are created, one each
-- actors timestamp and type of act should be enough to spot these dupes
-- the only parts that will change is props.owner and the key.id

module("hoe.acts")

--------------------------------------------------------------------------------
--
-- serving flavour can be used to create a subgame of a different flavour
-- make sure we incorporate flavour into the name of our stored data types
--
--------------------------------------------------------------------------------
function kind(H)
	if not H.srv.flavour or H.srv.flavour=="hoe" then return "hoe.act" end
	return H.srv.flavour..".hoe.act"
end

--------------------------------------------------------------------------------
--
-- Create a new local entity in H.round filled with initial data
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
	
	p.act="act"			-- what type of act this is, eg robbery, purchase etc
	
	p.type="act"		-- the type of action for more general grouping
	
	p.dupe=0			-- set to the id this act is a dupe of, or 0 if it is unique
						-- we record dupes for actions with multiple owners
	
	p.owner=0			-- the player whoes profile this act should be displayed on
	p.private=0			-- is this a private msgs? set to 0 if public or the player id if only intended for them
						-- so private==0 if we want a public stream
	
	p.actor1=0			-- the primary actor or 0 if none
	p.actor2=0			-- the secondary actor or 0 if none
	
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache
	
	
	c.data={} -- the data available for all templates, also includes some calculated entity data.

	return check(H,ent)
end

--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
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
-- Save to database
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
-- Load from database, pass in id or entity
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
-- change entity by a table, each value present is set
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
			if not f(H,e.cache) then t.rollback() return false end -- hard fail
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
-- given an entity return or update a list of memcache keys we should recalculate
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
		cache.del(srv,n)
	end
end

--------------------------------------------------------------------------------
--
-- convert entity into a "html" chunk or "text" line
--
--------------------------------------------------------------------------------
function plate(H,ent,plate)

	local t=html.get_plate("act_"..ent.cache.act.."_"..plate) or "{act}"	
	local c=ent.cache
	local d={}
	setmetatable(d,{__index=ent.cache.data}) -- use a meta table so we can
-- add some more basedata for use in the plate without disturbing the original datas

	d.url=H.srv.url_base..H.round.key.id.."/"
	d.act=c.act
	d.actor1=c.actor1
	d.actor2=c.actor2
	
	return wet_html.replace(t,d)
end

--------------------------------------------------------------------------------
--
-- add a shout act, tab should contain:
--
-- actor1	= id of player
-- shout	= that which was shouted
--
--------------------------------------------------------------------------------
function add_shout(H,tab)

	local e=create(H)
	local c=e.cache
	
	c.act="shout" -- type of act
	c.type="chat"
	c.owner=tab.actor1
	c.private=0
	c.actor1=tab.actor1
	c.actor2=0
	
	for i,v in pairs(tab) do -- just copy tab into data
		c.data[i]=v
	end
	
	put(H,e)
	
	return e
end
--------------------------------------------------------------------------------
--
-- add a namechange act, tab should contain:
--
-- actor1	= id of player
-- name1	= old name
-- name2	= new name
--
--------------------------------------------------------------------------------
function add_namechange(H,tab)

	local e=create(H)
	local c=e.cache
	
	c.act="namechange" -- type of act
	c.type="chat"
	c.owner=tab.actor1
	c.private=0
	c.actor1=tab.actor1
	c.actor2=0
	
	for i,v in pairs(tab) do -- just copy tab into data
		c.data[i]=v
	end
	
	put(H,e)
	
	return e
end


--------------------------------------------------------------------------------
--
-- add a tradeoffer act, tab should contain:
--
-- actor1	= id of player
-- name1	= name of player
-- offer	= name of item offered
-- seek		= name of item sought
-- count 	= number of items offered
-- cost		= number of items sought per items offered
-- price	= total number of items sought
--
--------------------------------------------------------------------------------
function add_tradeoffer(H,tab)

	local e=create(H)
	local c=e.cache
	
	c.act="tradeoffer" -- type of act
	c.type="trade"
	c.owner=tab.actor1
	c.private=0
	c.actor1=tab.actor1
	c.actor2=0
	
	for i,v in pairs(tab) do -- just copy tab into data
		c.data[i]=v
	end
	
	put(H,e)
	
	return e
end

--------------------------------------------------------------------------------
--
-- add a trade act, tab should contain:
--
-- actor1	= id of player
-- name1	= name of player
-- actor2	= id of buyer
-- name2	= name of buyer
-- offer	= name of item offered
-- seek		= name of item sought
-- count 	= number of items offered
-- cost		= number of items sought per items offered
-- price	= total number of items sought
--
--------------------------------------------------------------------------------
function add_trade(H,tab)

	local e=create(H)
	local c=e.cache
	
	c.act="trade" -- type of act
	c.type="trade"
	c.owner=tab.actor1
	c.private=0
	c.actor1=tab.actor1
	c.actor2=tab.actor2
	
	for i,v in pairs(tab) do -- just copy tab into data
		c.data[i]=v
	end
	
	put(H,e)
	local id=e.key.id
	
-- actor2 also gets the same act saved specially for them unless this is a self trade (buyback)
	if tab.actor1~=tab.actor2 then
		e.key.id=nil
		e.cache.id=nil
		e.cache.dupe=id -- flag as duplicate
		e.cache.owner=tab.actor2 -- just change the owner and put again
		put(H,e)
	end
	
	return e
end

--------------------------------------------------------------------------------
--
-- add a rob act, tab should contain:
--
-- actor1	= id of player
-- name1	= name of player
-- actor2	= id of victim
-- name2	= name of victim
-- bux		= amount of bux stolen
-- bros1    = number of bros attacker lost
-- sticks1  = number of sticks attacker lost
-- bros2    = number of bros defender lost
-- sticks2  = number of sticks defender lost
-- act      = "robwin" or "robfail" was this a win or fail?
--
--------------------------------------------------------------------------------
function add_rob(H,tab,fight)

	if fight then
		tab.bux     =  fight.cache.result.bux
		tab.bros1   = -fight.cache.sides[1].result.bros
		tab.sticks1 = -fight.cache.sides[1].result.sticks
		tab.bros2   = -fight.cache.sides[2].result.bros
		tab.sticks2 = -fight.cache.sides[2].result.sticks
		tab.act     =  fight.cache.act
	end
	
	local e=create(H)
	local c=e.cache
	
	c.act=tab.act -- type of act
	c.type="fight"
	c.owner=tab.actor1
	c.private=0
	c.actor1=tab.actor1
	c.actor2=tab.actor2
	
	for i,v in pairs(tab) do -- just copy tab into data
		c.data[i]=v
	end
	
	put(H,e)
	local id=e.key.id
	
-- actor2 also gets the same act saved specially for them
	e.key.id=nil
	e.cache.id=nil
	e.cache.dupe=id -- flag as duplicate
	e.cache.owner=tab.actor2 -- just change the owner and put again
	put(H,e)
	
	return e
end

--------------------------------------------------------------------------------
--
-- add a barnarson act, tab should contain:
--
-- actor1	= id of player
-- name1	= name of player
-- actor2	= id of victim
-- name2	= name of victim
-- house1	= number of houses attacker lost (always 0?)
-- bros1    = number of bros attacker lost
-- sticks1  = number of sticks attacker lost
-- house2	= number of houses defender lost
-- bros2    = number of bros defender lost
-- sticks2  = number of sticks defender lost
-- act      = "arsonwin" or "arsonfail" was this a win or fail?
--
--------------------------------------------------------------------------------
function add_arson(H,tab,fight)

	if fight then
		tab.bros1   = -fight.cache.sides[1].result.bros
		tab.sticks1 = -fight.cache.sides[1].result.sticks
		tab.houses1 = -fight.cache.sides[1].result.houses
		tab.bros2   = -fight.cache.sides[2].result.bros
		tab.sticks2 = -fight.cache.sides[2].result.sticks
		tab.houses2 = -fight.cache.sides[2].result.houses
		tab.act     =  fight.cache.act
	end

	local e=create(H)
	local c=e.cache
	
	c.act=tab.act -- type of act
	c.type="fight"
	c.owner=tab.actor1
	c.private=0
	c.actor1=tab.actor1
	c.actor2=tab.actor2
	
	for i,v in pairs(tab) do -- just copy tab into data
		c.data[i]=v
	end
	
	put(H,e)
	local id=e.key.id
	
-- actor2 also gets the same act saved specially for them
	e.key.id=nil
	e.cache.id=nil
	e.cache.dupe=id -- flag as duplicate
	e.cache.owner=tab.actor2 -- just change the owner and put again
	put(H,e)
	
	return e
end


--------------------------------------------------------------------------------
--
-- add a party act, tab should contain:
--
-- actor1	= id of player
-- name1	= name of player
-- actor2	= id of victim
-- name2	= name of victim
-- hoes1	= number of hoes attacker lost (always 0?)
-- manure1  = number of manure attacker lost
-- hoes2    = number of hoes defender lost
-- manure2  = number of manure defender lost
-- act      = "partywin" or "partyfail" was this a win or fail?
--
--------------------------------------------------------------------------------
function add_party(H,tab,fight)

	if fight then
		tab.hoes     =  fight.cache.result.hoes
		tab.manure1 = -fight.cache.sides[1].result.manure
		tab.manure2 = -fight.cache.sides[2].result.manure
		tab.act     =  fight.cache.act
	end

	local e=create(H)
	local c=e.cache
	
	c.act=tab.act -- type of act
	c.type="fight"
	c.owner=tab.actor1
	c.private=0
	c.actor1=tab.actor1
	c.actor2=tab.actor2
	
	for i,v in pairs(tab) do -- just copy tab into data
		c.data[i]=v
	end
	
	put(H,e)
	local id=e.key.id
	
-- actor2 also gets the same act saved specially for them
	e.key.id=nil
	e.cache.id=nil
	e.cache.dupe=id -- flag as duplicate
	e.cache.owner=tab.actor2 -- just change the owner and put again
	put(H,e)
	
	return e
end

--------------------------------------------------------------------------------
--
-- Load a list of actions from database
--
--------------------------------------------------------------------------------
function list(H,opts,t)
	opts=opts or {} -- stop opts from being nil
	
	t=t or dat -- use transaction?
	
	local q={
		kind=kind(H),
		limit=opts.limit or 100,
		offset=opts.offset or 0,
			{"filter","round_id","==",H.round.key.id},
		}
		
	for i,v in ipairs{"owner","private","act","type","dupe"} do
		if opts[v] then -- optional options
			q[#q+1]={"filter",v,"==",opts[v]}
		end
	end
	
	q[#q+1]={"sort","created","DESC"} -- blog LIFO order
		
	local r=t.query(q)
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end
