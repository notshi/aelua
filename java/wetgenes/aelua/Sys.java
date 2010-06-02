
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.IOException;
import javax.servlet.http.*;

import java.util.*;


public class Sys
{


	public Sys()
	{
	}

//
// Open this lib
//	
	public static int open(Lua L)
	{
		LuaTable lib=L.register("wetgenes.aelua.sys.core");
		Sys base=new Sys();
		
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
		L.setField(lib, "wetgenes.aelua.sys.core", new LuaJavaCallback(){ public int luaFunction(Lua L){ return Sys.open(L); } });
	}
	
//
// Add all callable functions and constants to the lib table
//
	int open_lib(Lua L,LuaTable lib)
	{
		
		reg_time(L,lib);
		reg_count(L,lib);
		
		return 0;
	}

//
// Return time in seconds since unix epoch, if you are lucky it may be acurate to milliseconds
//
	public void reg_time(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "time", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.time(L); } });
	}
	public int time(Lua L)
	{
		double t=System.currentTimeMillis();
		t=t/1000;
		L.push( t );
		return 1;
	}
	
//
// Return time in seconds thats has as much acuracy as possible but should only be compared to other
// values returned from this function. IE it is relative to an arbitary point and may wrap and go teh crazy
// just use it for unimportant benchmark tests
//
	public void reg_count(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "count", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.count(L); } });
	}
	public int count(Lua L)
	{
		double t=System.nanoTime();
		t=t/1000000000;
		L.push( t );
		return 1;
	}
	
}



