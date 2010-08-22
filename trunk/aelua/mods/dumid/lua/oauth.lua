

local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


local opts=require("opts")
local opts_users_admin=( opts and opts.users and opts.users.admin ) or {}


-- require all the module sub parts
local html=require("dumid.html")



local math=math
local string=string
local table=table
local os=os

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type
local pcall=pcall
local loadstring=loadstring


--
-- Which can be overidden in the global table opts
--
local opts_mods_dumid={}
if opts and opts.mods and opts.mods.dumid then opts_mods_dumid=opts.mods.dumid end


module("dumid.oauth")

local function esc(s)
	return string.gsub(s,'[^0-9A-Za-z%-._~]', -- RFC3986 happy chars
		function(c) return ( string.format("%%%02X", string.byte(c)) ) end )
end

local function hmac_sha1(key,str)
	local bin=srv.hmac_sha1(key,str,"bin") -- key gets used as is, I think string should be 7bit safe.
	local b64=srv.bin_encode("base64",bin) -- we need to convert the resuilt to base64
	return b64
end

function build(vars,opts)

	local post      =opts.post       or "POST" 
	local url       =opts.url        or ""
	local secret    =opts.secret     or ""
	local api_secret=opts.api_secret or ""

	local vals={}

-- esc and shove all oauth vars into vals
	for i,v in pairs(vars) do
		vals[#vals+1]={esc(i),esc(v)} -- record a simple table , i==[1] v==[2]
	end

	table.sort(vals, function(a,b)
			if a[1]==b[1] then return a[2]<b[2] end -- sort by [2] if [1] is the same
			return a[1]<b[1] -- other wise sort by [1]
		end)
		
-- now they are in the right order build the query string

	for i=1,#vals do local v=vals[i]
		vals[i]=v[1].."="..v[2]
	end
	local query=table.concat(vals,"&")
	local base=post.."&"..esc(url).."&"..esc(query) -- everything always gets escaped
	local key=esc(api_secret).."&"..esc(secret) -- the key is built from these strings
		
	return query.."&oauth_signature="..enc(hmac_sha1(key,base)) -- sign it
end


