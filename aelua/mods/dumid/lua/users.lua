
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

module("dumid.users")

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
	p.email="" -- this is a duplicate of the userid or maybe even a real email
	p.name=""
	p.parent="" -- set to a parent userid for linked accounts
	
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
-- get a user ent by id within the given transaction t
-- you may edit the cache values after this get in preperation for a put
--
-- an id (always all lowercase) is a user@domain string identifier
-- for instance 1234567@id.facebook.com which would indicate a facebook
-- account with the user id of 1234567
--
-- the id subdomain is used so as to seperate these ids from possibly
-- real emails at the various domains that could also be mixed in
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
function manifest(srv,userid,name,flavour)

	local user=create(srv)
	
	if not name or name=="" or name==userid then
	
		user.cache.name=str_split("@",userid)[1] -- build a name from email
		user.cache.name=string.sub(user.cache.name,1,32)
		
	else
	
		user.cache.name=name -- use given name
		
	end

	userid=string.lower(userid)

	user.key.id=userid -- email is the forcedkey value for this entity
	user.cache.id=userid -- email is the forcedkey value for this entity

	user.cache.flavour=flavour -- provider hint, we can mostly work this out from the email if missing
	
	user.cache.email=userid -- repeat the key

	return user
end










-----------------------------------------------------------------------------
--
-- convert a userid into a profile link, a 16x16 icon linked to a profile (html)
-- returns nil if we cant
-- also returns bare profile url in second argument
--
-----------------------------------------------------------------------------
function get_profile_link(userid)

	local url="/profile/"..userid
	local profile="<a href="..url.."><img src=\"/art/icon_goog.png\" /></a>"

	local endings={"@id.wetgenes.com"}
	for i,v in ipairs(endings) do
		if string.sub(userid,-#v)==v then
			profile="<a href="..url.."><img src=\"/art/icon_wet.png\" /></a>"
		end
	end

	local endings={"@id.twitter.com"}
	for i,v in ipairs(endings) do
		if string.sub(userid,-#v)==v then
			profile="<a href="..url.."><img src=\"/art/icon_twat.png\" /></a>"
		end
	end

	local endings={"@id.google.com"}
	for i,v in ipairs(endings) do
		if string.sub(userid,-#v)==v then
			profile="<a href="..url.."><img src=\"/art/icon_goog.png\" /></a>"
		end
	end

	return profile,url
end

-----------------------------------------------------------------------------
--
-- convert a userid into an avatar image url, 100x100 loaded via /thumbcache/100/100
-- so we cache it on site, pass in w,h for alternative sized avatar
--
-- this function may hit external sites and take some time to run
-- so cache it if you need it do not call this multiple times every page render
--
-----------------------------------------------------------------------------
function get_avatar_url(userid,w,h)
	local user=nil
	
	w=w or 100
	h=h or 100
	local url
	local email=userid
	
	if type(userid)=="table" then
		user=userid
		userid=user.id or ""
		email=userid
		if user.info and user.info.email then
			email=user.info.email
		end
	end
	if type(userid)=="string" then userid=userid:lower() end
	
	local endings={"@id.wetgenes.com"}
	for i,v in ipairs(endings) do
		if string.sub(userid,-#v)==v then
			url="/thumbcache/"..w.."/"..h.."/www.wetgenes.com/icon/"..string.sub(userid,1,-(#v+1))
		end
	end

	local endings={"@id.twitter.com"}
	for i,v in ipairs(endings) do
		if string.sub(userid,-#v)==v then

			local turl="http://www.twitter.com/users/"..string.sub(userid,1,-(#v+1))..".json"
			local got=fetch.get(turl) -- get twitter infos from internets
			if type(got.body)=="string" then
				local tab=json.decode(got.body)
				if tab.profile_image_url then
					url="/thumbcache/"..w.."/"..h.."/"..tab.profile_image_url:sub(8) -- skip "http://"
				end
			end

		end
	end

	url=url or "/thumbcache/"..w.."/"..h.."/www.gravatar.com/avatar/"..sys.md5(email):lower().."?s=200&d=identicon&r=x"
	
	return url -- return nil if no image found
end
