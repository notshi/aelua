
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

--------------------------------------------------------------------------------
--
-- Time to bite the bullet and clean up the session handling
-- so I can link users together for merged profiles
-- unfortunately this was one of the early bits of code so was
-- designed before I got the hange of using googles datastore
-- in fact it was my first use.
--
-- I hope I do not break anything :)
--
--------------------------------------------------------------------------------

module("dumid.sess")
dat.set_defs(_M) -- create basic data handling funcs

props=
{
	userid="", -- who this session belongs too
	ip="", -- and the ip this session belongs to
}

cache=
{
}

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function kind(srv)
	return "user.sess"
end

-----------------------------------------------------------------------------
--
-- Check a session ent
--
-----------------------------------------------------------------------------
function check(srv,ent)

	local ok=true
	local c=ent.cache
	local p=ent.props
	
	p.userid=c.userid or ""
	p.ip=c.ip or ""

	return ent,ok
end

-----------------------------------------------------------------------------
--
-- Make a local session data, ready to be put
--
-----------------------------------------------------------------------------
function manifest(srv,user,hash)

	local sess=create(srv)
	local p=ent.props
	local c=ent.cache

	ent.key.id=hash
	
	c.userid=user.key.id
	c.ip=srv.ip
	
	return sess
end



-----------------------------------------------------------------------------
--
-- delete all sessions with the given user id
-- 
-----------------------------------------------------------------------------
function del(userid)

	local r=dat.query({
		kind="user.sess",
		limit=100,
		offset=0,
			{"filter","userid","==",userid},
		})
	
	local mc={}
	for i=1,#r.list do local v=r.list[i]
		cache_what(srv,v,mc)
		dat.del(v.key)
	end
	cache_fix(srv,mc) -- remove cache of what was just deleted

end




-----------------------------------------------------------------------------
--
-- associates a future action with the active user, returns a key valid for 5 minutes
-- 
-----------------------------------------------------------------------------
function put_act(srv,user,dat)
	if not user or not dat then return nil end
	
local id=tostring(math.random(10000,99999)) -- need a random number but "random" isnt a big issue
	
local key="user=act&"..user.key.id.."&"..id

	cache.put(key,dat,60*5)
	
	return id
end

-----------------------------------------------------------------------------
--
-- retrives an action for this active user or nil if not a valid key
--
-----------------------------------------------------------------------------
function get_act(srv,user,id)
	if not user or not id then return nil end
	
local key="user=act&"..user.key.id.."&"..id
local dat=cache.get(key)

	if not dat then return nil end -- notfound
	
	cache.del(key) -- one use only
	
	return dat

end


-----------------------------------------------------------------------------
--
-- get the viewing user session
-- use our cookies and local lookup, not googles
-- googles users can map to our users via dum-id
--
-----------------------------------------------------------------------------
function get_viewer_session(srv)

	if srv.sess and srv.user then return srv.sess,srv.user end -- may be called multiple times
	
	local sess
	
	if srv.cookies.wet_session then -- we have a cookie session to check
	
		sess=get_sess(srv,srv.cookies.wet_session) -- this is probably a cache get
		
		if sess then -- need to validate
			if sess.cache.ip ~= srv.ip then -- ip must match, this makes stealing sessions a local affair.
				sess=nil
			end
		end
	end
	
	srv.sess=sess
	srv.user=nil
	if sess then
		srv.user=dumid_user.get(srv,sess.cache.userid) -- this is probably also a cache get
	end
	return srv.sess,srv.user -- return sess , user
	
end
