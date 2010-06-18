
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
		
		reg_get(L,lib);
		
		reg_resize(L,lib);
		
		reg_composite(L,lib);
		
		return 0;
	}

//
// Return a table of informaton abou an image represented by a byte string (just a string in normal lua)
//
	public void reg_get(Lua L,Object lib)
	{ 
		final Img _base=this;
		L.rawSet(lib, "get", new LuaJavaCallback(){ Img base=_base; public int luaFunction(Lua L){ return base.get(L); } });
	}
	public int get(Lua L)
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
		L.setField(t,"image",img);
		L.setField(t,"data",img.getImageData());
		L.setField(t,"format",img.getFormat().name());
		L.setField(t,"height",img.getHeight());
		L.setField(t,"width",img.getWidth());
	}
	public Image get_tab_img(Lua L,LuaTable t)
	{
		Image img;
		
		img=(Image)L.getField(t,"image"); // the cached image
		if(img==null)
		{
			img=ImagesServiceFactory.makeImage((byte[])L.getField(t,"data")); // or a new one
			L.setField(t,"image",img); // remember
		}
		
		return img;
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

		Image img=ImagesServiceFactory.makeImage( (byte[]) L.getField(tab,"data") );
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
		
		LuaTable t=L.newTable();
		fill_tab_img(L,t,img);
		L.push( t );
		return 1;
	}
	
//
// Composite some images into a new one, return that image
//
	public void reg_composite(Lua L,Object lib)
	{ 
		final Img _base=this;
		L.rawSet(lib, "composite", new LuaJavaCallback(){ Img base=_base; public int luaFunction(Lua L){ return base.composite(L); } });
	}
	public int composite(Lua L)
	{	
		int width=1;
		int height=1;
		long color=0;
		int i;
		Object o;
		LuaTable v;
		
		int x=1;
		int y=1;
		float opacity=1;
		Composite.Anchor anchor;
		String anchor_str;
		
		Image img;
		Image img2;
		LuaTable tab=(LuaTable)L.value(1);
		String format=(String)L.getField(tab,"format");
		width=((Double)L.getField(tab,"width")).intValue();
		height=((Double)L.getField(tab,"height")).intValue();
		color=((Double)L.getField(tab,"color")).intValue();
		
		LinkedList t1 = new LinkedList();
		
		i=0;
		do
		{
			o=tab.getnum(++i);
			if(L.isTable(o))
			{
				v=(LuaTable)o;
				img2=get_tab_img(L,(LuaTable)v.getnum(1));
				x=((Double)v.getnum(2)).intValue();
				y=((Double)v.getnum(3)).intValue();
				opacity=((Double)v.getnum(4)).floatValue();
				anchor_str=(String)v.getnum(5);
				anchor=Composite.Anchor.valueOf(anchor_str);
				
				 t1.add( ImagesServiceFactory.makeComposite(img2,x,y,opacity,anchor) );
			}
		}
		while(!L.isNil(o));

		
		if(format=="JPEG")
		{
			img=imgs.composite(t1,width,height,color,ImagesService.OutputEncoding.JPEG);
		}
		else
		{
			img=imgs.composite(t1,width,height,color);
		}
		
		LuaTable t=L.newTable();
		fill_tab_img(L,t,img);
		L.push( t );
		return 1;
	}
}
