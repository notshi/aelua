
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.FileReader;
import java.io.IOException;
import javax.servlet.http.*;

import java.util.*;

import com.google.appengine.api.images.*;

public class Img
{


	public Img()
	{
	}

//
// Open this lib
//	
	public static int open(Lua L)
	{
		LuaTable lib=L.register("wetgenes.aelua.img.core");
		Img base=new Img();
		
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
		L.setField(lib, "wetgenes.aelua.img.core", new LuaJavaCallback(){ public int luaFunction(Lua L){ return Img.open(L); } });
	}
	
//
// Add all callable functions and constants to the lib table
//
	int open_lib(Lua L,LuaTable lib)
	{
		
		reg_get_img(L,lib);
		
		return 0;
	}

//
// Return a table of informaton abou an image represented b a byte string (just a string in normal lua)
//
	public void reg_get_img(Lua L,Object lib)
	{ 
		final Img _base=this;
		L.rawSet(lib, "get_img", new LuaJavaCallback(){ Img base=_base; public int luaFunction(Lua L){ return base.get_img(L); } });
	}
	public int get_img(Lua L)
	{
	
		Object a1=L.value(1);
		
		Image img=ImagesServiceFactory.makeImage((byte[])a1);
		
		LuaTable t=L.newTable();
		
		L.setField(t,"img",img);
		L.setField(t,"format",img.getFormat().name());
		L.setField(t,"height",img.getHeight());
		L.setField(t,"width",img.getWidth());
		
		L.push( t );
		return 1;
	}
	
}
