
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

	public User()
	{
		us = UserServiceFactory.getUserService();
	}

//
// Open this lib
//	
	public static int open(Lua L)
	{
		LuaTable lib=L.register("wetgenes.aelua.user.core");
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
		L.setField(lib, "wetgenes.aelua.user.core", new LuaJavaCallback(){ public int luaFunction(Lua L){ return User.open(L); } });
	}
	
//
// Add all callable functions and constants to the lib table
//
	int open_lib(Lua L,LuaTable lib)
	{
		reg_get(L,lib);
		
		return 0;
	}

//
// Get an entity of the given key and return its data
//
	void reg_get(Lua L,Object lib)
	{ 
		final User _base=this;
		L.setField(lib, "get", new LuaJavaCallback(){ User base=_base; public int luaFunction(Lua L){ return base.get(L); } });
	}
	int get(Lua L)
	{
		L.push("poopyhead");
		return 1;
	}
	
}



