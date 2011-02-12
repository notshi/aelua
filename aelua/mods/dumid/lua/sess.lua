
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

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
function kind(srv)
	return "user.sess"
end

-----------------------------------------------------------------------------
--
-- Make a local session ent
--
-----------------------------------------------------------------------------
function create(srv)

	local ent={}
	
	ent.key={kind=kind(srv)} -- we will not know the key id until after we save
	ent.props={}
	
	local p=ent.props
	
	p.created=srv.time
	p.updated=srv.time

	p.userid="" -- this is the userid unique key
	
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache

	return check(srv,ent)
end

-----------------------------------------------------------------------------
--
-- Check a session ent
--
-----------------------------------------------------------------------------
function check(srv,ent)

	local ok=true
	local c=ent.cache

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

	c.userid=user.cache.userid or user.cache.email
	
	c.user=user -- save a copy of the user in this session
	
-- make sure these are more than just cache values	
	p.userid=c.userid
	
	return sess
end



-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
function get(srv,hash,tt)
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
function put(srv,sess,tt)
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
function del(userid)

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
function put_act(srv,user,dat)
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
function get_act(srv,user,id)
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
