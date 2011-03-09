
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_diff=require("wetgenes.diff")


-- require all the module sub parts
local html=require("blog.html")



local math=math
local string=string
local table=table
local os=os

local ipairs=ipairs
local pairs=pairs
local tostring=tostring
local tonumber=tonumber
local type=type
local pcall=pcall
local loadstring=loadstring


--
-- Which can be overeiden in the global table opts
--
local opts_mods_waka={}
if opts and opts.mods and opts.mods.waka then opts_mods_waka=opts.mods.waka end

module("blog.pages")

--------------------------------------------------------------------------------
--
-- serving flavour can be used to create a submod of a different flavour
-- make sure we incorporate flavour into the name of our stored data types
--
--------------------------------------------------------------------------------
function kind(srv)
	if not srv.flavour or srv.flavour=="blog" then return "blog.pages" end
	return srv.flavour..".blog.pages"
end

--------------------------------------------------------------------------------
--
-- what key name should we use to cache an entity?
--
--------------------------------------------------------------------------------
function cache_key(pubname)
	return "type=ent&blog="..pubname
end

--------------------------------------------------------------------------------
--
-- Create a new local entity filled with initial data
--
--------------------------------------------------------------------------------
function create(srv)

	local ent={}
	
	ent.key={kind=kind(srv)} -- we will not know the key id until after we save
	ent.props={}
	
	local p=ent.props
	
	p.created=srv.time
	p.updated=srv.time

	p.group="/" -- master group of this post, "/" by default, this is the directory part of the pubname
	
	p.author="" -- userid of last editor of this post
	
	p.pubname="" -- the published name of this page if published, or "" if not published yet
	p.pubdate=srv.time  -- the date published (unixtime)

	p.layer=0 -- we use layer 0 as live and published, other layers for special or hidden pages
	
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache
	
	c.text="" -- this string is the main text of the data, it contains waka chunks
	
	c.comment_count=0 -- number of comments

	return check(srv,ent)
end

--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function check(srv,ent)
	if not ent then return nil,false end
	
	local ok=true

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
function put(srv,ent,t)

	t=t or dat -- use transaction?

	local _,ok=check(srv,ent) -- check that this is valid to put
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
function get(srv,id,t)

	local ent=id
	
	if type(ent)~="table" then -- get by id
		ent=create(srv)
		ent.key.id=id
	end
	
	t=t or dat -- use transaction?
	
	if not t.get(ent) then return nil end	
	dat.build_cache(ent)
	
	return check(srv,ent)
end



--------------------------------------------------------------------------------
--
-- get - update - put
--
-- f must be a function that changes the entity and returns true on success
-- id can be an id or an entity from which we will get the id
--
--------------------------------------------------------------------------------
function update(srv,id,f)

	if type(id)=="table" then id=id.key.id end -- can turn an entity into an id
		
	for retry=1,10 do
		local mc={}
		local t=dat.begin()
		local e=get(srv,id,t)
		if e then
			what_memcache(srv,e,mc) -- the original values
			if e.props.created~=srv.time then -- not a newly created entity
				if e.cache.updated>=srv.time then t.rollback() return false end -- stop any updates that time travel
			end
			e.cache.updated=srv.time -- the function can change this change if it wishes
			if not f(srv,e) then t.rollback() return false end -- hard fail
			check(srv,e) -- keep consistant
			if put(srv,e,t) then -- entity put ok
				if t.commit() then -- success
					what_memcache(srv,e,mc) -- the new values
					fix_memcache(srv,mc) -- change any memcached values we just adjusted
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
function what_memcache(srv,ent,mc)
	local mc=mc or {} -- can supply your own result table for merges	
	local c=ent.cache
	
	mc[ cache_key(c.pubname) ] = true
	
	return mc
end

--------------------------------------------------------------------------------
--
-- fix the memcache items previously produced by what_memcache
-- probably best just to delete them so they will automatically get rebuilt
--
--------------------------------------------------------------------------------
function fix_memcache(srv,mc)
	for n,b in pairs(mc) do
		cache.del(srv,n)
		srv.cache[n]=nil
	end
end


--------------------------------------------------------------------------------
--
-- list pages
--
--------------------------------------------------------------------------------
function list(srv,opts,t)
	opts=opts or {} -- stop opts from being nil
	
	t=t or dat -- use transaction?
	
	local q={
		kind=kind(srv),
		limit=opts.limit or 100,
		offset=opts.offset or 0,
	}
	
-- add filters?
	for i,v in ipairs{"layer","group"} do
		if opts[v] then
			local t=type(opts[v])
			if t=="string" or t=="number" then
				q[#q+1]={"filter",v,"==",opts[v]}
			end
		end
	end
	
	if     opts.sort=="pubdate" then q[#q+1]={"sort","pubdate","DESC"} -- newest published
	elseif opts.sort=="updated" then q[#q+1]={"sort","updated","DESC"} -- newest updated
	end
		
	local r=t.query(q)
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end

--------------------------------------------------------------------------------
--
-- find a page by its published name
--
--------------------------------------------------------------------------------
function find_by_pubname(srv,pubname,t)

	t=t or dat -- use transaction?
	
	local q={
		kind=kind(srv),
		limit=1,
		offset=0,
		{"filter","pubname","==",pubname},
		{"sort","layer","ASC"}, -- on multiple layers, pick the lowest one
	}
	local r=t.query(q)
	
	if r.list[1] then
		dat.build_cache(r.list[1])
		check(srv,r.list[1])
		return r.list[1]
	end

	return nil
end



--------------------------------------------------------------------------------
--
-- like find but with as much cache as we can use so ( no transactions available )
--
--------------------------------------------------------------------------------
function cache_find_by_pubname(srv,pubname)

	local key=cache_key(pubname)
	local ent=cache.get(srv,key)

	if type(ent)=="boolean" then return nil end -- not found

	if not ent then
		ent=find_by_pubname(srv,pubname)
		cache.put(srv,key,ent or false,60*60)
	end
	
	return (check(srv,ent))
end

