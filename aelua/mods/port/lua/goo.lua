
local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")
local cache=require("wetgenes.aelua.cache")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local oauth=require("wetgenes.aelua.oauth")

local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")

-- require all the module sub parts
local html=require("port.html")



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


-- opts
local opts_mods_port=(opts and opts.mods and opts.mods.port) or {}

module("port.goo")

--
-- shorten a url , returns the new url
--

function shorten(url)

	local got=fetch.post("https://www.googleapis.com/urlshortener/v1/url?key=AIzaSyBvpbJCF1Pl-VENOr09NXHdO8xryGDH0Sg",
		{
--			["Authorization"]="OAuth "..table.concat(auths,", "),
			["Content-Type"]="application/json; charset=utf-8",
		},json.encode({longUrl=url}) )

	local ret=json.decode(got.body)

	return ret.id or url
end


