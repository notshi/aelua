
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local Json=require("Json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")

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
local os=os

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
local function make_put(srv)
	return function(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end
end
-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=users.get_viewer_session(srv)
local put=make_put(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]
	
-- functions for each special command
	local cmds={
		login=		serv_login,
		logout=		serv_logout,
		callback=	serv_callback,
	}
	local f=cmds[ string.lower(cmd or "") ]
	if f then return f(srv) end
	
-- no command given
-- work out what we should do

	return serv_login(srv) -- try login by default?
		
end

-----------------------------------------------------------------------------
--
-- perform a tye of login, probably an offsite redirect
--
-----------------------------------------------------------------------------
function serv_login(srv)
local put=make_put(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]
	local dat=srv.url_slash[ srv.url_slash_idx+1 ]

	local continue="/"
	if srv.gets.continue then continue=srv.gets.continue end -- where we wish to end up
	
	if dat=="wetgenes" then
	
		local callback=srv.url_base.."callback/wetgenes/?continue="..wet_html.url_esc(continue)
		local tld="com"
		if srv.url_slash[3]=="localhost:8080" then tld="local" end
		return srv.redirect("http://lua.wetgenes."..tld.."/dumid.lua?continue="..wet_html.url_esc(callback))
		
	elseif dat=="google" then
	
		local callback=srv.url_base.."callback/google/?continue="..wet_html.url_esc(continue)
		return srv.redirect(users.login_url(callback))
		
	end

	srv.set_mimetype("text/html")
	put("dumid_header",{})
	put("dumid_choose",{continue=continue})	
	put("dumid_footer",{})
	
end

-----------------------------------------------------------------------------
--
-- callback part, after some magical login elsewhere, build a session then continue
--
-----------------------------------------------------------------------------
function serv_callback(srv)
local put=make_put(srv)

	local cmd= srv.url_slash[ srv.url_slash_idx+0 ]
	local data=srv.url_slash[ srv.url_slash_idx+1 ]

	local continue="/"
	if srv.gets.continue then continue=srv.gets.continue end -- where we wish to end up
	
	local user
	local sess
	local email
	local name
	local admin=false
	
	if data=="wetgenes" then
	
		if srv.gets.confirm then
		
			local hash=wet_html.url_esc(srv.gets.confirm)
			
			local callback=srv.url_base.."callback/wetgenes/?continue="..wet_html.url_esc(continue)
			local tld="com"
			if srv.url_slash[3]=="localhost:8080" then tld="local" end
			local s="http://lua.wetgenes."..tld.."/dumid.lua?continue="..wet_html.url_esc(callback)
			
			local got=fetch.get(s.."&hash="..hash) -- ask for confirmation from server
			if type(got.body=="string") then
				got=Json.Decode(got.body)
				if got.id then -- we now know who they are
					name=got.name
					email=got.id.."@id.wetgenes.com"
				end
			end
		
		end
			
	elseif data=="google" then
	
		local guser=users.core.user -- google handles its own login
		if guser then -- google login OK
			email=guser.email
			name=guser.name
			admin=guser.admin
		end
		
	end
	
	if email then -- try and load or create a new user by email
		for retry=1,10 do -- get or create user in database
			
			local t=dat.begin()
			
			user=users.get_user(email,t) -- try and read a current user
			
			if not user then -- didnt get, so make and put a new user?
			
				user=users.new_user(email,name) -- name can be nil, it will just be created from the email
				if not users.put_user(user,t) then user=nil end
			end

			if user.cache.admin~=admin then -- check admin flag
				user.cache.admin=admin
				if not users.put_user(user,t) then user=nil end
			end
			
			if user then -- things are looking good try a commit (we may not have actually written anything)
				if t.commit() then break end -- success
			end
			
			t.rollback()	
		end
	end
	
	if user then -- we got us a user now save it in a session
	
		-- remove all old sessions associated with this user?	
--		users.del_sess(user.email)
	
		-- create a new session for this user
		
		local hash=""
		for i=1,8 do
			hash=hash..string.format("%04x", math.random(0,65535) ) -- not so good but meh it will do for now
		end
		sess=users.new_sess(hash,user)
		sess.cache.ip=srv.ip -- lock to this ip?
		users.put_sess(sess) -- dump the session
		srv.set_cookie{name="wet_session",value=hash,domain=srv.domain,path="/",live=os.time()+(60*60*24*28)}
	end

	return srv.redirect(continue)
--[[
	srv.set_mimetype("text/html")
	put("dumid_header",{})	
	put("dumid_choose",{continue=continue})	
	put("dumid_footer",{})
]]
	
end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
function serv_logout(srv)
local sess,user=users.get_viewer_session(srv)
local put=make_put(srv)

	local cmd=srv.url_slash[ srv.url_slash_idx+0 ]
	local data=srv.url_slash[ srv.url_slash_idx+1 ]

	local continue="/"
	if srv.gets.continue then continue=srv.gets.continue end -- where we wish to end up
	
	if user and data then
		if data==sess.key.id then -- simple permission check
			users.del_sess(user.cache.email) -- kill all sessions
		end
	end
	
	srv.redirect(continue)
	
end
