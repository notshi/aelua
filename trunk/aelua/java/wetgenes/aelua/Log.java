
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.IOException;
import javax.servlet.http.*;

import java.util.*;

import java.util.logging.Logger;

public class Log
{

	Logger log;

	public Log()
	{
		log = Logger.getLogger(Log.class.getName());
	}

//
// Open this lib
//	
	public static int open(Lua L)
	{
		LuaTable lib=L.register("wetgenes.aelua.log.core");
		Log base=new Log();
		
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
		L.setField(lib, "wetgenes.aelua.log.core", new LuaJavaCallback(){ public int luaFunction(Lua L){ return Log.open(L); } });
	}
	
//
// Add all callable functions and constants to the lib table
//
	int open_lib(Lua L,LuaTable lib)
	{
		reg_log(L,lib);
		
		return 0;
	}

	public void reg_log(Lua L,Object lib)
	{ 
		final Log _base=this;
		L.setField(lib, "log", new LuaJavaCallback(){ Log base=_base; public int luaFunction(Lua L){ return base.log(L); } });
	}
	
	
	public int log(Lua L)
	{
		String s1=L.checkString(1);
		String s2;
		
		if(L.isString(L.value(2))) // we have two args, logtype,logstring
		{
			s2=L.checkString(2);
		}
		else // we have only one arg, so set logtype to info
		{
			s2=s1;
			s1="info";
		}
		
		if(s1=="info")
		{
			log.info(s2);
		}
		else
		if(s1=="warning")
		{
			log.warning(s2);
		}
		else
		if(s1=="severe")
		{
			log.severe(s2);
		}
		
		return 0;
	}

	
}



