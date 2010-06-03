local core=require("wetgenes.aelua.user.core")local string=stringlocal wet_string=require("wetgenes.string")local str_split=wet_string.str_splitlocal serialize=wet_string.serializemodule("wetgenes.aelua.user")function login_url(a)	return core.login_url(a)endfunction logout_url(a)	return core.logout_url(a)endif core.user then -- mirror the user data from within the core	user={}		user.email=core.user.email	user.name=core.user.name	user.admin=core.user.admin	if not user.name or user.name=="" or user.name==user.email then			user.name=str_split("@",user.email)[1]				string.sub(user.name,1,32)		end	user.email=string.lower(user.email) -- make sure the email is all lowercaseend