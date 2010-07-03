
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.IOException;
import javax.servlet.http.*;

import java.util.*;

import com.google.appengine.api.users.*;

public class User
{

	UserService us;
	com.google.appengine.api.users.User u;

	public User()
	{
		us = UserServiceFactory.getUserService();
		
		u=us.getCurrentUser();
	}

//
// Open this lib
//	
	public static int open(Lua L)
	{
		LuaTable lib=L.register("wetgenes.aelua.users.core");
		User base=new User();
		
		base.open_lib(L,lib);
				
		return 0;
	}

//
// Call this to setup a package preload function which opens this lib on demand
//
	public static int preload(Lua L)
	{
		if (L.findTable(L.getGlobals(), "package.preload", 0) != null)
		{
			L.error("package.preload missing");
		}
		LuaTable lib=(LuaTable)L.value(-1);
		L.pop(1);

		reg_preload(L,lib);

		return 0;
	}
	static void reg_preload(Lua L,Object lib)
	{ 
		L.setField(lib, "wetgenes.aelua.users.core", new LuaJavaCallback(){ public int luaFunction(Lua L){ return User.open(L); } });
	}
	
//
// Add all callable functions and constants to the lib table
//
	int open_lib(Lua L,LuaTable lib)
	{
		reg_login_url(L,lib);
		reg_logout_url(L,lib);
		
		
		if(u!=null)
		{
			LuaTable usr=L.createTable(0,0);
			L.rawSet(lib,"user",usr); // we have a user
			
			L.rawSet(usr,"admin",us.isUserAdmin()); // do we have an admin?	
		
			if(u.getAuthDomain()!=null)			{ L.rawSet(usr,"domain",u.getAuthDomain()); }
			if(u.getEmail()!=null)				{ L.rawSet(usr,"email",u.getEmail()); }
			if(u.getNickname()!=null)			{ L.rawSet(usr,"name",u.getNickname()); }
			
//			if(u.getUserId()!=null)				{ L.rawSet(usr,"id",u.getUserId()); }
//			if(u.getFederatedIdentity()!=null)	{ L.rawSet(usr,"fid",u.getFederatedIdentity()); }
		}
		
		
		return 0;
	}

//
// Get a url to login and then return
//
	void reg_login_url(Lua L,Object lib)
	{ 
		final User _base=this;
		L.setField(lib, "login_url", new LuaJavaCallback(){ User base=_base; public int luaFunction(Lua L){ return base.login_url(L); } });
	}
	int login_url(Lua L)
	{
		String s1=L.checkString(1);
		
		L.push(us.createLoginURL(s1));
		return 1;
	}
	
//
// Get a url to logout and then return
//
	void reg_logout_url(Lua L,Object lib)
	{ 
		final User _base=this;
		L.setField(lib, "logout_url", new LuaJavaCallback(){ User base=_base; public int luaFunction(Lua L){ return base.logout_url(L); } });
	}
	int logout_url(Lua L)
	{
		String s1=L.checkString(1);
		
		L.push(us.createLogoutURL(s1));
		return 1;
	}
	
}



