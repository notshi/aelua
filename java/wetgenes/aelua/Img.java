
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
	ImagesService imgs;

	public Img()
	{
		imgs=ImagesServiceFactory.getImagesService();
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
		reg_get_dat(L,lib);
		
		reg_resize(L,lib);
		
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
		
		fill_tab_img(L,t,img);
		
		L.push( t );
		return 1;
	}
	public void fill_tab_img(Lua L,LuaTable t,Image img)
	{
		L.setField(t,"img",img);
		L.setField(t,"format",img.getFormat().name());
		L.setField(t,"height",img.getHeight());
		L.setField(t,"width",img.getWidth());
	}
	
//
// Return a chunk of data bytearray that represents the image
//
	public void reg_get_dat(Lua L,Object lib)
	{ 
		final Img _base=this;
		L.rawSet(lib, "get_dat", new LuaJavaCallback(){ Img base=_base; public int luaFunction(Lua L){ return base.get_dat(L); } });
	}
	public int get_dat(Lua L)
	{	
		Object tab=L.value(1);

		Image img=(Image)L.getField(tab,"img");
		
		byte[] d=img.getImageData();

		L.push( d );
		return 1;
	}
	
//
// Resize the image, it may end up smaller in one dimension than the requested size
//
	public void reg_resize(Lua L,Object lib)
	{ 
		final Img _base=this;
		L.rawSet(lib, "resize", new LuaJavaCallback(){ Img base=_base; public int luaFunction(Lua L){ return base.resize(L); } });
	}
	public int resize(Lua L)
	{	
		int width=1;
		int height=1;
		
		LuaTable tab=(LuaTable)L.value(1);
		width=(int)L.checkNumber(2);
		height=(int)L.checkNumber(3);

		Image img=(Image)L.getField(tab,"img");
		String format=(String)L.getField(tab,"format");
		
		Transform t1=ImagesServiceFactory.makeResize(width,height);  
		
		if(format=="JPEG")
		{
			img=imgs.applyTransform(t1,img,ImagesService.OutputEncoding.JPEG);
		}
		else
		{
			img=imgs.applyTransform(t1,img);
		}
		
		fill_tab_img(L,tab,img);
		L.push( tab );
		return 1;
	}
}
