
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.IOException;
import javax.servlet.http.*;

import java.util.*;

import com.google.appengine.api.memcache.*;

public class Cache
{

	MemcacheService ms;

	public Cache()
	{
		ms =  MemcacheServiceFactory.getMemcacheService();
	}

//
// Open this lib
//	
	public static int open(Lua L)
	{
		LuaTable lib=L.register("wetgenes.aelua.cache.core");
		Cache base=new Cache();
		
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
		L.setField(lib, "wetgenes.aelua.cache.core", new LuaJavaCallback(){ public int luaFunction(Lua L){ return Cache.open(L); } });
	}
	
//
// Add all callable functions and constants to the lib table
//
	int open_lib(Lua L,LuaTable lib)
	{
		reg_del(L,lib);
		reg_put(L,lib);
		reg_get(L,lib);
		
		reg_inc(L,lib);
		
		
		return 0;
	}

	
//
// Lua cache del function
//
	void reg_del(Lua L,Object lib)
	{ 
		final Cache _base=this;
		L.setField(lib, "del", new LuaJavaCallback(){ Cache base=_base; public int luaFunction(Lua L){ return base.del(L); } });
	}
	int del(Lua L)
	{
		Object o;
		
		o=L.value(1);
		if(!L.isString(o)) { L.error("cache name must be a string"); }
		String nam=(String)o;

		L.push(				ms.delete(nam)				? Boolean.TRUE : Boolean.FALSE );
		
		return 1;
	}
	
//
// Lua cache get function
//
	void reg_get(Lua L,Object lib)
	{ 
		final Cache _base=this;
		L.setField(lib, "get", new LuaJavaCallback(){ Cache base=_base; public int luaFunction(Lua L){ return base.get(L); } });
	}
	int get(Lua L)
	{
		Object o;
		
		o=L.value(1);
		if(!L.isString(o)) { L.error("cache name must be a string"); }
		String nam=(String)o;
		Object ret=ms.get(nam);

		if(ret==null)
		{
			L.pushNil();
		}
		else
		{
			L.push( ret );
		}
		return 1;
	}
	
//
// Lua cache put function
//
	void reg_put(Lua L,Object lib)
	{ 
		final Cache _base=this;
		L.setField(lib, "put", new LuaJavaCallback(){ Cache base=_base; public int luaFunction(Lua L){ return base.put(L); } });
	}
	int put(Lua L)
	{
		Object o;
		
		o=L.value(1);
		if(!L.isString(o)) { L.error("cache name must be a string"); }
		String nam=(String)o;

		Object dat=L.value(2);
//		if(!L.isString(o)) { L.error("cache data must be a string"); }
//		String dat=(String)o;
		
		Double num=new Double(60*60); // one hour default
		o=L.value(3);
		if(L.isNil(o)) {  } else // default
		if(L.isNumber(o))
		{
			num=L.toNumber(o);
		}
		else { L.error("cache expiry must be number of seconds to live"); }

		MemcacheService.SetPolicy pol=MemcacheService.SetPolicy.SET_ALWAYS;
		o=L.value(4);
		if(L.isNil(o)) {  } else // default
		if(L.isString(o))
		{
			pol=MemcacheService.SetPolicy.valueOf(L.toString(o));
		}
		else { L.error("cache setpolicy is invalid"); }
		
		Expiration exp=Expiration.byDeltaSeconds(num.intValue());
		
		L.push(				ms.put(nam,dat,exp,pol)				? Boolean.TRUE : Boolean.FALSE );
		
		return 1;
	}
	
//
// Lua cache inc function,  a get/put combined to adjust a number
//
	void reg_inc(Lua L,Object lib)
	{ 
		final Cache _base=this;
		L.setField(lib, "inc", new LuaJavaCallback(){ Cache base=_base; public int luaFunction(Lua L){ return base.inc(L); } });
	}
	int inc(Lua L)
	{
		Object o;
		
		o=L.value(1);
		if(!L.isString(o)) { L.error("cache name must be a string"); }
		String nam=(String)o;

		o=L.value(2);
		if(!L.isNumber(o)) { L.error("cache data must be a number"); }
		Double num=(Double)o;

		Double init=new Double(0);
		o=L.value(3);
		if(L.isNil(o)) {  } else // default
		if(L.isNumber(o))
		{
			init=L.toNumber(o);
		}
		else { L.error("cache initial number must be a number"); }
		
		L.push(		ms.increment(nam,num.longValue(),new Long(init.longValue()))		);
		
		return 1;
	}
}



