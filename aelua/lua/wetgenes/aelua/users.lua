
local json=require("json")

local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local log=require("wetgenes.aelua.log").log -- grab the func from the package



local core=require("wetgenes.aelua.users.core")

local os=os
local string=string
local math=math

local tostring=tostring

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
function get_sess(hash,tt)
	local cachekey="user=sess&"..hash
	
	if not tt then -- not a transaction so try memcache first
		local data=cache.get(cachekey)
		if data then -- found in memcache
			local d=json.decode(data) -- turn into table
			local sess=new_sess(hash,d.user) -- build a body
			sess.cache=d -- and replace the cache
			d.user=get_user(d.user.key.id) -- refresh user
			return sess
		end
	end
		
	local t=tt or dat
	if t.fail then return nil end
	
	local sess={key={kind="user.sess",id=hash}} -- hash is the key value for this entity
	
	if not t.get(sess) then return nil end -- failed to get
	
	dat.build_cache(sess) -- most data is kept in json
	
	sess.cache.user=get_user(sess.cache.user.key.id,tt) -- refresh user
	
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
-- Make a local user data, ready to be put
--
-----------------------------------------------------------------------------
function new_user(email,name,flavour)

	local user={key={kind="user.data",id=string.lower(email)}} -- email is the key value for this entity
	user.props={}
	
	user.props.flavour=flavour -- provider hint, we can mostly work this out from the email if missing
	
	user.props.email=string.lower(email) -- make sure the email is all lowercase
	
	if not name or name=="" or name==email then
	
		user.props.name=str_split("@",email)[1] -- build a name from email
		user.props.name=string.sub(user.props.name,1,32)
		
	else
	
		user.props.name=name -- use given name
		
	end
	
	user.props.created=os.time() -- created stamp
	user.props.updated=user.props.created -- update stamp
	
	
	dat.build_cache(user) -- create the default cache
	
	return user
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
function get_user(email,t)
	t=t or dat
	if t.fail then return nil end
	
	local user={key={kind="user.data",id=string.lower(email)}} -- email is key value for this empty entity
	
	if not t.get(user) then return nil end -- failed to get
	
	dat.build_cache(user) -- most data is kept in json
	
	return user
end
-----------------------------------------------------------------------------
--
-- convert the cache values to props then
-- put a previously got user ent within the given transaction t
-- pass in dat instead of a transaction if you do not need one
--
-- after a succesful commit do a got_user_data(ent) to update the current user
-- 
-----------------------------------------------------------------------------
function put_user(user,t)
	t=t or dat
	if t.fail then return nil end
	
	dat.build_props(user) -- most data is kept in json
	
	user.props.updated=os.time() -- update stamp
	
	return t.put(user)
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
	
		sess=get_sess(srv.cookies.wet_session) -- load session
		
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

