
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
local wet_util=require("wetgenes.util")

-- require all the module sub parts
local html=require("port.html")


local lookup=wet_util.lookup

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

module("port.twitter")

--
-- make a twat update
--
-- it.user -- the user (must be a twitter user)
-- it.text -- 140 characters
--

function post(it)
local it=it or {}

-- check it is a twitter user before going further
	if not lookup(it,"user","cache","authentication","twitter","secret") then return end

	local v={}
	v.oauth_timestamp , v.oauth_nonce = oauth.time_nonce("sekrit")
	v.oauth_consumer_key = opts_twitter.key
	v.oauth_signature_method="HMAC-SHA1"
	v.oauth_version="1.0"
		
	v.oauth_token=lookup(it,"user","cache","authentication","twitter","token")
	v.status=it.text

	local o={}
	o.post="POST"
	o.url="http://api.twitter.com/1/statuses/update.json"
	v.tok_secret=lookup(it,"user","cache","authentication","twitter","secret")
	o.api_secret=opts_twitter.secret
	
	local k,q = oauth.build(v,o)
	local b={}
	
	for _,n in pairs({"status"}) do
		b[n]=v[n]
		v[n]=nil
	end
	v.oauth_signature=k

	local vals={}
	for ii,iv in pairs(b) do
		vals[#vals+1]=oauth.esc(ii).."="..oauth.esc(iv)
	end
	local q=table.concat(vals,"&")
	
	local auths={}
	for ii,iv in pairs(v) do
		auths[#auths+1]=oauth.esc(ii).."=\""..oauth.esc(iv).."\""
	end

	local got=fetch.post(o.url.."?"..q,
		{
			["Authorization"]="OAuth "..table.concat(auths,", "),
			["Content-Type"]="x-www-form-urlencoded; charset=utf-8",
		},q) -- get from internets

end


