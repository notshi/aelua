
local json=require("json")

local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local fetch=require("wetgenes.aelua.fetch")
local sys=require("wetgenes.aelua.sys")


local core=require("wetgenes.aelua.users.core")

local os=os
local string=string
local math=math

local tostring=tostring
local type=type
local ipairs=ipairs

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

module("wetgenes.aelua.users")



function login_url(a)

	return core.login_url(a)

end


function logout_url(a)

	return core.logout_url(a)

end

function get_google_user()

	return core.get_google_user()

end



--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function kind(srv)
	return "user.data"
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

	p.flavour=""
	p.email=""
	p.name=""
		
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache

	return check(srv,ent)
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

-----------------------------------------------------------------------------
--
-- convert the cache values to props then
-- put a previously got user ent within the given transaction t
-- pass in dat instead of a transaction if you do not need one
--
-----------------------------------------------------------------------------
function put(srv,ent,t)

	t=t or dat -- use transaction?

	local _,ok=check(srv,ent) -- check that this is valid to put
	if not ok then return nil end

	dat.build_props(ent)
	local ks=t.put(ent)
	
	if ks then
		ent.key=dat.keyinfo( ks ) -- update key with new id
		dat.build_cache(ent)
	end

	return ks -- return the keystring which is an absolute name
end


-----------------------------------------------------------------------------
--
-- get a user ent by email within the given transaction t
-- you may edit the cache values after this get in preperation for a put
--
-- an email (always all lowercase) is a user@domain string identifier
-- sometimes this may not be a real email but just indicate a unique account
-- for instance 1234567@id.facebook.com 
-- email is just used as a convienient term for such strings
-- it harkens to the day when facebook will finally forfill the prophecy
-- of every application evolving to the point where it can send and recieve email
-- I notice that myspace already has...
--
-----------------------------------------------------------------------------
function get(srv,id,t)

	local ent=id
	
	if type(ent)~="table" then -- get by id
		ent=create(srv)
		ent.key.id=id
	end
	
	t=t or dat -- use transaction?
	
	if not t.get(ent) then return nil end	
	dat.build_cache(ent)
	
	return check(srv,ent)
end





-----------------------------------------------------------------------------
--
-- Make a local user data, ready to be put
--
-----------------------------------------------------------------------------
function manifest(srv,email,name,flavour)

	local user=create(srv)
	
	if not name or name=="" or name==email then
	
		user.cache.name=str_split("@",email)[1] -- build a name from email
		user.cache.name=string.sub(user.cache.name,1,32)
		
	else
	
		user.cache.name=name -- use given name
		
	end

	email=string.lower(email)

	user.key.id=email -- email is the forcedkey value for this entity
	user.cache.id=email -- email is the forcedkey value for this entity

	user.cache.flavour=flavour -- provider hint, we can mostly work this out from the email if missing
	
	user.cache.email=email -- repeat the key
	
	
	return user
end











-----------------------------------------------------------------------------
--
-- Make a local session data, ready to be put or updated
--
-----------------------------------------------------------------------------
function new_sess(hash,user)

	local sess={key={kind="user.sess",id=hash}} -- hash is the key value for this entity
	sess.props={}

	sess.props.created=os.time() -- created stamp
	sess.props.updated=sess.props.created -- update stamp
	sess.props.email=user.cache.email -- so we can find sessions belonging to this user again later
	
	dat.build_cache(sess) -- create the default cache
	
	sess.cache.user=user -- we cache the user inside the session data
	
	-- just update the user and the  put the session again if you need to
	-- or throw any other data into the cache and put it
	
	return sess
end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
function get_sess(srv,hash,tt)
	local cachekey="user=sess&"..hash
	
	if not tt then -- not a transaction so try memcache first
		local data=cache.get(cachekey)
		if data then -- found in memcache
			local d=json.decode(data) -- turn into table
			local sess=new_sess(hash,d.user) -- build a body
			sess.cache=d -- and replace the cache
			d.user=get(srv,d.user.key.id) -- refresh user
			return sess
		end
	end
		
	local t=tt or dat
	if t.fail then return nil end
	
	local sess={key={kind="user.sess",id=hash}} -- hash is the key value for this entity
	
	if not t.get(sess) then return nil end -- failed to get
	
	dat.build_cache(sess) -- most data is kept in json
	
	sess.cache.user=get(srv,sess.cache.user.key.id,tt) -- refresh user
	
	if not tt then -- not a transaction so write it to memcache as well
		cache.put(cachekey,json.encode(sess.cache),60*60)
	end
	return sess
end
-----------------------------------------------------------------------------
--
-- 
-----------------------------------------------------------------------------
function put_sess(sess,tt)
	local t=tt or dat
	if t.fail then return nil end
		
	dat.build_props(sess) -- most data is kept in json
	
	sess.props.updated=os.time() -- update stamp
	
	local r=t.put(sess)
	if not tt then
		cache.del("user=sess&"..sess.key.id) -- remove any memcache, after the put
							--- (any transaction code will need to do this *again* after a commit)
	end
	return r
end

-----------------------------------------------------------------------------
--
-- delete all sessions with the given email
-- 
-----------------------------------------------------------------------------
function del_sess(email)

	local r=dat.query({
		kind="user.sess",
		limit=100,
		offset=0,
			{"filter","email","==",email},
		})
		
	for i=1,#r.list do local v=r.list[i]
		dat.del(v.key)
		cache.del("user=sess&"..v.key.id) -- remove any memcache, after the del
	end

end


-----------------------------------------------------------------------------
--
-- associates a future action with the active user, returns a key valid for 5 minutes
-- 
-----------------------------------------------------------------------------
function put_act(user,dat)
	if not user or not dat then return nil end
	
local id=tostring(math.random(10000,99999)) -- need a random number but "random" isnt a big issue
	
local key="user=act&"..user.cache.email.."&"..id
local str=json.encode(dat)

	cache.put(key,str,60*5)
	
	return id
end

-----------------------------------------------------------------------------
--
-- retrives an action for this active user or nil if not a valid key
--
-----------------------------------------------------------------------------
function get_act(user,id)
	if not user or not id then return nil end
	
local key="user=act&"..user.cache.email.."&"..id
local str=cache.get(key)

	if not str then return nil end -- notfound
	
	cache.del(key) -- one use only
	
	return json.decode(str)

end


-----------------------------------------------------------------------------
--
-- get the viewing user session
-- use our cookies and local lookup, not googles
-- googles users can map to our users via dum-id
--
-----------------------------------------------------------------------------
function get_viewer_session(srv)

	if srv.sess then return srv.sess,srv.user end -- may be called multiple times
	
	local sess
	
	if srv.cookies.wet_session then -- we have a cookie session to check
	
		sess=get_sess(srv,srv.cookies.wet_session) -- load session
		
		if sess then -- need to validate
			if sess.cache.ip ~= srv.ip then -- ip must match, this makes stealing sessions a local affair.
				sess=nil
			end
		end
	end
	
	srv.sess=sess
	srv.user=sess and sess.cache and sess.cache.user -- and put the user somewhere easier
	
	return sess,srv.user -- return sess , user
	
end


-----------------------------------------------------------------------------
--
-- convert an email into a profile link, a 16x16 icon linked to a profile
-- returns nil if we cant, return url in second argument
--
-----------------------------------------------------------------------------
function email_to_profile_link(email)

	local url="/profile/"..email
	local profile="<a href="..url.."><img src=\"/art/icon_goog.png\" /></a>"

	local endings={"@id.wetgenes.com"}
	for i,v in ipairs(endings) do
		if string.sub(email,-#v)==v then
			url="http://like.wetgenes.com/-/profile/$"..string.sub(email,1,-(#v+1))
			profile="<a href="..url.."><img src=\"/art/icon_wet.png\" /></a>"
		end
	end

	local endings={"@id.twitter.com"}
	for i,v in ipairs(endings) do
		if string.sub(email,-#v)==v then
			url="/js/dumid/twatbounce.html?id="..string.sub(email,1,-(#v+1))
			profile="<a href="..url.."><img src=\"/art/icon_twat.png\" /></a>"
		end
	end
--[[
	local endings={"@gmail.com","@googlemail.com"}
	for i,v in ipairs(endings) do
		if string.sub(email,-#v)==v then
			url="http://www.google.com/profiles/"..string.sub(email,1,-(#v+1))
			profile="<a href="..url.."><img src=\"/art/icon_goog.png\" /></a>"
		end
	end
]]

	return profile,url
end

-----------------------------------------------------------------------------
--
-- convert an email into an avatar image url, 100x100 loaded via /thumbcache/100/100
-- so we cache it on site, pass in w,h for alternative sized avatar
--
-- this function may hit external sites and take some time to run
-- so cache it if you need it do not call this multiple times every page render
--
-----------------------------------------------------------------------------
function email_to_avatar_url(email,w,h)
	w=w or 100
	h=h or 100
	local url


	local endings={"@id.wetgenes.com"}
	for i,v in ipairs(endings) do
		if string.sub(email,-#v)==v then
			url="/thumbcache/"..w.."/"..h.."/www.wetgenes.com/icon/"..string.sub(email,1,-(#v+1))
		end
	end

	local endings={"@id.twitter.com"}
	for i,v in ipairs(endings) do
		if string.sub(email,-#v)==v then

			local turl="http://www.twitter.com/users/"..string.sub(email,1,-(#v+1))..".json"
			local got=fetch.get(turl) -- get twitter infos from internets
			if type(got.body)=="string" then
				local tab=json.decode(got.body)
				if tab.profile_image_url then
					url="/thumbcache/"..w.."/"..h.."/"..tab.profile_image_url:sub(8) -- skip "http://"
				end
			end

		end
	end

--[[
	local endings={"@gmail.com","@googlemail.com"}
	for i,v in ipairs(endings) do
		if string.sub(email,-#v)==v then
			url="http://www.google.com/profiles/"..string.sub(email,1,-(#v+1))
		end
	end
]]

	url=url or "/thumbcache/"..w.."/"..h.."/www.gravatar.com/avatar/"..sys.md5(email):lower().."?s=200&d=identicon&r=x"
	
	return url -- return nil if no image found
end
