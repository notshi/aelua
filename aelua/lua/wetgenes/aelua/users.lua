local Json=require("Json")local dat=require("wetgenes.aelua.data")local cache=require("wetgenes.aelua.cache")local log=require("wetgenes.aelua.log").log -- grab the func from the packagelocal core=require("wetgenes.aelua.users.core")local os=oslocal string=stringlocal math=mathlocal tostring=tostringlocal wet_string=require("wetgenes.string")local str_split=wet_string.str_splitlocal serialize=wet_string.serializemodule("wetgenes.aelua.users")function login_url(a)	return core.login_url(a)endfunction logout_url(a)	return core.logout_url(a)end--------------------------------------------------------------------------------- Make a local user data, ready to be put-------------------------------------------------------------------------------function new_user(email,name)	local user={key={kind="user.data",id=string.lower(email)}} -- email is the key value for this entity	user.props={}		user.props.email=string.lower(email) -- make sure the email is all lowercase		if not name or name=="" or name==email then			user.props.name=str_split("@",email)[1] -- build a name from email		user.props.name=string.sub(user.props.name,1,32)			else			user.props.name=name -- use given name			end		user.props.created=os.time() -- created stamp	user.props.updated=user.props.created -- update stamp		dat.build_cache(user) -- create the default cache		return userend--------------------------------------------------------------------------------- get a user ent by email within the given transaction t-- pass in dat instead of a transaction if you do not need one-- you may edit the cache values after this get in preperation for a put---- an email (always all lowercase) is a user@domain string identifier-- sometimes this may not be a real email but just indicate a unique account-- for instance 1234567@id.facebook.com -- email is just used as a convienient term for such strings-- it harkens to the day when facebook will finally forfill the prophecy-- of every application evolving to the point where it can send and recieve email-- I notice that myspace already has...-------------------------------------------------------------------------------function get_user(email,t)	t=t or dat	if t.fail then return nil end		local user={key={kind="user.data",id=string.lower(email)}} -- email is key value for this empty entity		if not t.get(user) then return nil end -- failed to get		dat.build_cache(user) -- most data is kept in json		return userend--------------------------------------------------------------------------------- convert the cache values to props then-- put a previously got user ent within the given transaction t-- pass in dat instead of a transaction if you do not need one---- after a succesful commit do a got_user_data(ent) to update the current user-- -----------------------------------------------------------------------------function put_user(user,t)	t=t or dat	if t.fail then return nil end		dat.build_props(user) -- most data is kept in json		user.props.updated=os.time() -- update stamp		return t.put(user)end--------------------------------------------------------------------------------- associates a future action with the active user, returns a key valid for 5 minutes-- -----------------------------------------------------------------------------function put_act(user,dat)	if not user or not dat then return nil end	local id=tostring(math.random(10000,99999)) -- need a random number but "random" isnt a big issue	local key="user=act&"..user.cache.email.."&"..idlocal str=Json.Encode(dat)	cache.put(key,str,60*5)		return idend--------------------------------------------------------------------------------- retrives an action for this active user or nil if not a valid key-------------------------------------------------------------------------------function get_act(user,id)	if not user or not id then return nil end	local key="user=act&"..user.cache.email.."&"..idlocal str=cache.get(key)	if not str then return nil end -- notfound		cache.del(key) -- one use only		return Json.Decode(str)end--------------------------------------------------------------------------------- get the viewing user-------------------------------------------------------------------------------function get_viewer()	local user	if core.user then -- is there a viewer?		for retry=1,10 do -- get or create user in database						local t=dat.begin()						user=get_user(core.user.email,t) -- try and read a current user						if not user then -- didint get, so make and put a new user?							user=new_user(core.user.email,core.user.name)								if not put_user(user,t) then user=nil end			end						if user then -- things are looking good try a commit (we may not have actually written anything)				if t.commit() then break end -- success			end						t.rollback()			end				user.admin=core.user.admin -- copy admin flag for ease of access	end		return user -- may be nilend