
local json=require("json")

local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local fetch=require("wetgenes.aelua.fetch")
local sys=require("wetgenes.aelua.sys")


local os=os
local string=string
local math=math

local tostring=tostring
local type=type
local ipairs=ipairs

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


module("dumid.acts")

-----------------------------------------------------------------------------
--
-- associates a future action with the active user, returns a key valid for 5 minutes
-- this data is only stored in the cache so if the cache breaks so does this
-- system
-- 
-----------------------------------------------------------------------------
function put(srv,user,dat)
	if not user or not dat then return nil end
	
local id=tostring(math.random(10000,99999)) -- need a random number but "random" isnt a big issue
	
local key="user=act&"..user.cache.id.."&"..id
local str=json.encode(dat)

	cache.put(key,str,60*5) -- store for 5 mins
	
	return id
end

-----------------------------------------------------------------------------
--
-- retrives an action for this active user or nil if not a valid key
--
-----------------------------------------------------------------------------
function get(srv,user,id)
	if not user or not id then return nil end
	
local key="user=act&"..user.cache.id.."&"..id
local str=cache.get(key)

	if not str then return nil end -- notfound
	
	cache.del(key) -- one use only
	
	return json.decode(str)

end
