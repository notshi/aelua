
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

--local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")
local user=users.get_viewer()

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html=require("dumid.html")



local math=math
local string=string
local table=table

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type
local pcall=pcall
local loadstring=loadstring


--
-- Which can be overeiden in the global table opts
--
local opts_mods_dumid={}
if opts and opts.mods and opts.mods.dumid then opts_mods_dumid=opts.mods.dumid end

module("dumid")

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)
	local function put(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]
	local dat=srv.url_slash[ srv.url_slash_idx+1 ]
	
-- functions for each special command
	local cmds={
		login=	serv_login,
		logout=	serv_logout,
	}
	local f=cmds[ string.lower(cmd or "") ]
	if f then return f(srv) end
	
-- no command given
-- work out what we should do

	return serv_login(srv) -- try and login by default
		
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv_login(srv)
	local function put(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]
	local dat=srv.url_slash[ srv.url_slash_idx+1 ]

	local continue="/"
	if srv.gets.continue then continue=srv.gets.continue end -- where we wish to end up
	
	if dat=="wetgenes" then
		local tld="com"
		if srv.url_slash[3]=="localhost:8080" then tld="local" end
		return srv.redirect("http://lua.wetgenes."..tld.."/dumid.lua?continue="..continue)
	elseif dat=="google" then
		return srv.redirect(users.login_url(continue))
	end

	srv.set_mimetype("text/html")
	put("dumid_header",{})
	put("dumid_choose",{continue=continue})	
	put("dumid_footer",{})
	
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv_logout(srv)
	local function put(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]
	local dat=srv.url_slash[ srv.url_slash_idx+1 ]

	local continue="/"
	if srv.gets.continue then continue=srv.gets.continue end -- where we wish to end up
	
	if user then
		return srv.redirect(users.logout_url(continue))
	end

	srv.set_mimetype("text/html")
	put("dumid_header",{})
	put("dumid_logout",{continue=continue})	
	put("dumid_footer",{})
	
end
