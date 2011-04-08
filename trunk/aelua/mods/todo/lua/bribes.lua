
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

module("todo.bribes")
dat.set_defs(_M) -- create basic data handling funcs

-- the key used should be thing.."/"..user so one bribe per user per thing
default_props=
{
	thing="", -- things id eg "/todo/something"
	user="", -- users id eg "1234@id.gmail.com"
	bribe=0, -- a 0 bribe + benefits is perfectly valid
	state="none",
}

default_cache=
{
	extras="",
}



--------------------------------------------------------------------------------
--
-- allways this kind
--
--------------------------------------------------------------------------------
function kind(srv)
	return "todo.bribe"
end

--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function check(srv,ent)

	local ok=true
	local c=ent.cache
		
	return ent,ok
end








