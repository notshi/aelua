


local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")
local cache=require("wetgenes.aelua.cache")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


local opts=require("opts")
local opts_users_admin=( opts and opts.users and opts.users.admin ) or {}
local opts_twitter=( opts and opts.twitter ) or {}


-- require all the module sub parts
local html=require("dumid.html")
local oauth=require("dumid.oauth")



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
		if srv.url_slash[3]=="host.local:8080" then tld="local" end
		return srv.redirect("http://lua.wetgenes."..tld.."/dumid.lua?continue="..wet_html.url_esc(callback))
		
	elseif dat=="google" then
	
		local callback=srv.url_base.."callback/google/?continue="..wet_html.url_esc(continue)
		return srv.redirect(users.login_url(callback))
		
	elseif dat=="twitter" then
	
		local callback=srv.url_base.."callback/twitter/?continue="..wet_html.url_esc(continue)
		local baseurl="https://twitter.com/oauth/request_token"

		local vars={}
		vars.oauth_timestamp , vars.oauth_nonce = oauth.time_nonce("sekrit")
		vars.oauth_consumer_key = opts_twitter.key
		vars.oauth_signature_method="HMAC-SHA1"
		vars.oauth_version="1.0"
		vars.oauth_callback=callback
	
		local k,q = oauth.build(vars,{post="GET",url=baseurl,api_secret=opts_twitter.secret})
		
		local got=fetch.get(baseurl.."?"..q) -- get from internets		
		local gots=oauth.decode(got.body)
		
		if gots.oauth_token then
			cache.put("oauth_token="..gots.oauth_token,got.body) -- save data for a little while
			return srv.redirect("https://twitter.com/oauth/authorize?oauth_token="..gots.oauth_token)
		end
	end

	srv.set_mimetype("text/html; charset=UTF-8")
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
	local flavour
	local admin=false
	local authentication={} -- store any values we wish to cache here
	
	if data=="wetgenes" then
	
		if srv.gets.confirm then
		
			local hash=wet_html.url_esc(srv.gets.confirm)
			
			local callback=srv.url_base.."callback/wetgenes/?continue="..wet_html.url_esc(continue)
			local tld="com"
			if srv.url_slash[3]=="host.local:8080" then tld="local" end
			local s="http://lua.wetgenes."..tld.."/dumid.lua?continue="..wet_html.url_esc(callback)
			
			local got=fetch.get(s.."&hash="..hash) -- ask for confirmation from server
			if type(got.body=="string") then
				got=json.decode(got.body)
				if got.id then -- we now know who they are
					name=got.name
					email=got.id.."@id.wetgenes.com"
					flavour="wetgenes"
				end
			end
		
		end
			
	elseif data=="google" then
	
		local guser=users.core.user -- google handles its own login
		if guser then -- google login OK
			email=guser.email
			name=guser.name
			admin=guser.admin
			flavour="google"
		end
		
	elseif data=="twitter" then

		local gots=cache.get("oauth_token="..srv.gets.oauth_token) -- recover data
		if gots then gots=oauth.decode(gots) else gots={} end -- decode it again
		
-- ok now we get to ask twitter for an actual username using this junk we have collected so far

		local baseurl="https://twitter.com/oauth/access_token"
		
		local vars={}
		vars.oauth_timestamp , vars.oauth_nonce = oauth.time_nonce("sekrit")
		vars.oauth_consumer_key = opts_twitter.key
		vars.oauth_signature_method="HMAC-SHA1"
		vars.oauth_version="1.0"
		vars.oauth_token=gots.oauth_token
		vars.oauth_verifier=srv.gets.oauth_verifier
	
		local k,q = oauth.build(vars,{post="GET",url=baseurl,
			api_secret=opts_twitter.secret,tok_secret=gots.oauth_token_secret})
		
		local got=fetch.get(baseurl.."?"..q) -- simple get from internets		
		local data=oauth.decode(got.body or "")
		
		if data.screen_name then -- we got a user
		
			name=data.screen_name
			email=data.user_id.."@id.twitter.com"
			flavour="twitter"
					
			authentication.twitter={ -- all the twitter info we should also keep track of
				token=data.oauth_token,
				secret=data.oauth_token_secret,
				name=data.screen_name,
				id=data.user_id,
				}
		end
	
	end
	
	if email then -- try and load or create a new user by email
		if opts_users_admin[email] then admin=true end -- set admin flag to true for these users

		for retry=1,10 do -- get or create user in database
			
			local t=dat.begin()
			
			user=users.get_user(email,t) -- try and read a current user
			
			if not user then -- didnt get, so make and put a new user?
			
				user=users.new_user(email,name,flavour) -- name can be nil, it will just be created from the email
				if not users.put_user(user,t) then user=nil end
			end
			
			if user then
				user.cache.flavour=flavour
				user.cache.authentication=user.cache.authentication or {} -- may need to create
				for i,v in pairs(authentication) do -- remember any new special authentication values
					user.cache.authentication[i]=v
				end
			end

			user.cache.admin=admin
			if not users.put_user(user,t) then user=nil end -- always write
			
			if user then -- things are looking good try a commit
				if t.commit() then break end -- success
			end
			
			t.rollback()	
		end
	end
	
	if user then -- we got us a user now save it in a session
	
		-- remove all old sessions associated with this user?	
		users.del_sess(user.cache.email)
	
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
	srv.set_mimetype("text/html; charset=UTF-8")
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
