
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
local wet_waka=require("wetgenes.waka")


-- require all the module sub parts
local html=require("waka.html")
local edits=require("waka.edits")



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

module("waka.pages")

--------------------------------------------------------------------------------
--
-- serving flavour can be used to create a subgame of a different flavour
-- make sure we incorporate flavour into the name of our stored data types
--
--------------------------------------------------------------------------------
function kind(srv)
	if not srv.flavour or srv.flavour=="waka" then return "waka.pages" end
	return srv.flavour..".waka.pages"
end

--------------------------------------------------------------------------------
--
-- what key name should we use to cache an entity?
--
--------------------------------------------------------------------------------
function cache_key(id)
	if type(id)=="table" then -- convert ent to id
		id=id.key.id
	end
	return "type=ent&waka="..id
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
	
-- the layer is also used in the key name by appending ?layer=1 if it is set to 1 
-- when it is 0 then the key name needs no layer to be appended, this apendage is
-- intended to mimic urls in the creation of unique keys
	p.layer=0
	p.group=""
	
	p.tags={}
	
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache
	
	c.text="" -- this string is the main text of the data, it contains waka chunks

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
	
	if c.id then -- build group from path, we might need to list all pages in a group
		local aa=str_split("/",c.id,true)
		aa[#aa]=nil
		local group="/" -- default master group
		if aa[1] and aa[2] then group=table.concat(aa,"/") end
		c.group=group
	end
		
	return ent,ok
end

--------------------------------------------------------------------------------
--
-- Save to database
-- this calls check before putting and does not put if check says it is invalid
-- build_props is called so code should always be updating the cache values
--
--------------------------------------------------------------------------------
function put(srv,ent,tt)

--	ent.cache.tags={["a"]=true,["bb"]=true,["ccc"]=true}
	
	local t=tt or dat -- use transaction?

	local _,ok=check(srv,ent) -- check that this is valid to put
	if not ok then return nil end

	dat.build_props(ent)
	local ks=t.put(ent)
	
	if ks then
		ent.key=dat.keyinfo( ks ) -- update key with new id
		dat.build_cache(ent)
	end

	if not tt then fix_memcache(srv,what_memcache(srv,ent)) end

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
	
	if t then 
		if not t.get(ent) then return nil end	
	else
		return cache_get(srv,ent.key.id)
	end
	dat.build_cache(ent)

---log(tostring(ent.cache.tags))
	
	return check(srv,ent)
end

--------------------------------------------------------------------------------
--
-- get or create a blank page
--
--------------------------------------------------------------------------------
function manifest(srv,id,t)

	local ent=get(srv,id,t)
--	if t then ent=get(srv,id,t) else ent=cache_get(srv,id) end --cache get?
	
	if not ent then -- make new
		ent=create(srv)
		ent.key.id=id -- force id which is page name string
		ent.cache.id=id -- copy here
		ent.cache.text="#title\n"..string.gsub(id,"/"," ").."\n#body\n".."MISSING CONTENT\n"
		ent.key.notsaved=true -- flag as not saved yet
	end
	
	return check(srv,ent)
end

--------------------------------------------------------------------------------
--
-- change the text of this page, creating it if necesary
--
--------------------------------------------------------------------------------
function edit(srv,id,by)

	local f=function(srv,e)
		local c=e.cache
	
		local text=by.text or c.text
		local author=by.author or ""
		local note=by.note or ""
		
	
		c.last=c.edit -- also remember the last edit, which may be null
		
		local d={}
		c.edit=d -- remember what we just changed in edit, 
		
		d.from=e.props.updated -- old time stamp
		d.time=e.cache.updated -- new time stamp
		
		d.diff=wet_diff.diff(c.text, text) -- what was changed		
		
		if #d.diff==1 then return false end-- no changes, no need to write, so return a fail to stop it
		
		d.author=author
		d.note=note
		
		c.text=text -- change the actual text
		
		c.tags=by.tags or c.tags -- remember updated tags in an index
		
		return true
	end		
	return update(srv,id,f)
end

--------------------------------------------------------------------------------
--
-- create a new edit entry in the history, the entity will know what has just changed
-- we check that the last edit also exists (there are many reasons why it may not)
-- if it does we store a delta if it doesnt we store a delta AND current full text
-- as such there are technical limits to page sizes that are less than normal google limits.
-- So probably best to keep pages less than 500k I'd say 256k is a good maximum string size
-- to aim for and big enough for an entire book to be stored in one page.
--
--------------------------------------------------------------------------------
function add_edit_log(srv,e,fulltext)
local c=e.cache

	local edit
	
	if c.last then -- find old edit
		local old=edits.find(srv,{page=e.key.id,from=c.last.from,time=c.last.time})
		if not old then fulltext=true end -- mising last edit 
	else
		fulltext=true -- flag a full text dump
	end
	
	if c.edit then -- what to save
		edit=edits.create(srv)
		edit.cache.page=e.key.id
		edit.cache.group=e.cache.group
		edit.cache.layer=e.cache.layer
		edit.cache.from=c.edit.from
		edit.cache.time=c.edit.time
		edit.cache.diff=c.edit.diff
		edit.cache.author=c.edit.author
		
		if fulltext then -- include full text
			edit.cache.text=c.text
		end
		
		edits.put(srv,edit)
	end
	
	return edit -- may be null or maybe the edit we just created
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
		local e=manifest(srv,id,t)
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
					add_edit_log(srv,e) -- also adjust edits history
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
	
	mc[ cache_key(ent) ]=true
	
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
	
	local r=t.query({
		kind=kind(srv),
		limit=opts.limit or 100,
		offset=opts.offset or 0,
			{"filter","layer","==",0},
			{"sort","updated","DESC"},
		})
		
	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end



--------------------------------------------------------------------------------
--
-- like get but with as much cache as we can use so ( no transactions available )
--
--------------------------------------------------------------------------------
function cache_get(srv,id)
	local key=cache_key(id)
	local ent=cache.get(srv,key)

	if type(ent)=="boolean" then return nil end -- if cache is set to false then there is nothing to get
	
	if not ent then -- otherwise read from database
		ent=get(srv,id,dat) -- stop recursion by passing in dat as the transaction
		cache.put(srv,key,ent or false,60*60) -- and save into cache for an hour
	end

	return (check(srv,ent))
end


--------------------------------------------------------------------------------
--
-- load the page and all of its parent pages then build refined chunks.
-- return all the chunks, with the refined chunks found in [0]
-- unless unrefined is set in the opts, the opts are also passed into refine_chunks
--
--------------------------------------------------------------------------------
function load(srv,id,opts)
	opts=opts or {}

	local pages={}
	local chunks
	local name=id
	
	pages[#pages+1]=wet_waka.text_to_chunks( manifest(srv,name).cache.text ) -- start with main page	
	if id~="/" then -- if asking for root then no need to look for anything else
		while string.find(name,"/") do -- whilst there are still / in the name	
			name=string.gsub(name,"/[^/]*$","") -- remove the tail from the string			
			if name~="" then -- skip empty
				pages[#pages+1]=wet_waka.text_to_chunks( manifest(srv,name).cache.text )
			end
		end
		pages[#pages+1]=wet_waka.text_to_chunks( manifest(srv,"/").cache.text ) -- finally always include root
	end
	
-- merge all pages
	for i=#pages,1,-1 do
		chunks=wet_waka.chunks_merge(chunks,pages[i])
	end
	
 -- build refined chunks
	if not opts.unrefined then
		chunks[0]=wet_waka.refine_chunks(srv,chunks,opts)
	end
	
	return chunks
end
