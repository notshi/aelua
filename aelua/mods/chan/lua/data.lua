
-- this all needs to be rewritten now i know what I'm doing :)


-- load up html template strings
local html=require("wetgenes.html")

local json=require("json")

local sys=require("wetgenes.aelua.sys")

local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize



local tostring=tostring
local ipairs=ipairs
local os=os

local math=math
local string=string


module("chan.data")


-----------------------------------------------------------------------------
--
-- trim the subject and body and raise any errors over missing params
--
-----------------------------------------------------------------------------
local function preprocess_post(tab)

	tab.subject=string.sub(tab.subject,1,256)
	tab.body=string.sub(tab.body,1,4096)

end


local function msg_ent(tab)

	local t=os.time()
	
	local ent={}
	
	local dat={
		subject=tab.subject,
		body=tab.body,
		image=tab.image,
		}
	ent.props={
		email=tab.email,
		ip=tab.ip,
		json=json.encode(dat),
		updated=t,
		created=t,
		}
		
	return ent
end


-----------------------------------------------------------------------------
--
-- create a new thread in the datastore
--
-- email   -- lowercase only email of poster
-- subject -- subject of post < 256 chars
-- body    -- body of post < 4096 chars
-- image   -- image url
--
-- returns the key of the new entity
--
-----------------------------------------------------------------------------
function create_thread(tab)

	preprocess_post(tab)

	local ent=msg_ent(tab)
	
	ent.key={kind="chan.thread"} -- no parent
	
	local key=dat.put(ent)

	return key
end

-----------------------------------------------------------------------------
--
-- create a new image in the datastore
--
-- image -- image info
-- thumb -- thumb info
--
-- returns the numerical id of the new entitys, use this + kind to show images
--
-----------------------------------------------------------------------------
function create_image(tab)

	local ent={}
	
	ent.key={kind="chan.image"} -- no parent and autogenerate an id
	ent.props={
		width=tab.image.width,
		height=tab.image.height,
		format=tab.image.format,
		data=tab.image.data,
		}
	
	local key=dat.put(ent)
	
	local keyinfo=dat.keyinfo(key)
	local id=keyinfo.id

	ent={}
	
	ent.key={kind="chan.thumb",id=id} -- use same id as the main image for easy lookup
		ent.props={
		width=tab.thumb.width,
		height=tab.thumb.height,
		format=tab.thumb.format,
		data=tab.thumb.data,
		}
		
	local key=dat.put(ent)
		
	return id -- return image id
end

-----------------------------------------------------------------------------
--
-- create a new post in the datastore
--
-- parent  -- key of the parent thread
-- email   -- lowercase only email of poster
-- subject -- subject of post < 256 chars
-- body    -- body of post < 4096 chars
-- image   -- image url
--
-- returns the key of the new entity
--
-----------------------------------------------------------------------------
function create_post(tab)

	preprocess_post(tab)
	
	local ent=msg_ent(tab)
		
	ent.key={kind="chan.post",parent=tab.parent} -- parent is a thread
	
	local key=dat.put(ent)

	return key
	
end

-----------------------------------------------------------------------------
--
-- get an array of threads
--
-----------------------------------------------------------------------------
function get_threads(how)

	local t=dat.query({
		kind="chan.thread",
		limit=10,
		offset=0,
			{"sort","updated","<"},
		})
		
	for i,v in ipairs(t.list) do
		dat.build_cache(v)
	end
		
	return t.list
end
