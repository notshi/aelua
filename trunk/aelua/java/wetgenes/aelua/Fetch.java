
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.IOException;
import javax.servlet.http.*;

import java.util.*;
import java.net.*;

import com.google.appengine.api.urlfetch.*;

public class Fetch
{
	URLFetchService fetcher;

	public Fetch()
	{
		fetcher = URLFetchServiceFactory.getURLFetchService();
	}

//
// Open this lib
//	
	public static int open(Lua L)
	{
		LuaTable lib=L.register("wetgenes.aelua.fetch.core");
		Fetch base=new Fetch();
		
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
		L.setField(lib, "wetgenes.aelua.fetch.core", new LuaJavaCallback(){ public int luaFunction(Lua L){ return Fetch.open(L); } });
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
// A simple and blocking url get
//
	void reg_get(Lua L,Object lib)
	{ 
		final Fetch _base=this;
		L.setField(lib, "get", new LuaJavaCallback(){ Fetch base=_base; public int luaFunction(Lua L){ return base.get(L); } });
	}
	int get(Lua L)
	{
		String s=L.checkString(1); // url to fetch
		
		try
		{
			LuaTable t=L.newTable();
			
			URL url = new URL(s);
			HTTPResponse response = fetcher.fetch(url);
			
			URL finalUrl = response.getFinalUrl();
			if(finalUrl!=null) // we got redirected to here
			{
				L.rawSet(t,"redirected",finalUrl.toString());
			}
			
			int responseCode = response.getResponseCode();
			L.rawSet(t,"code",responseCode);

			LuaTable h=L.newTable();
			L.rawSet(t,"headers",h);
			
			String bodytype="BYTE";
			
			List headers = response.getHeaders();
			for(Object o : headers)
			{
				HTTPHeader header=(HTTPHeader)o; // silly type errors bore me
				
				String headerName = header.getName();
				String headerValue = header.getValue();
				L.rawSet(h,headerName,headerValue);
				
				if(headerName.compareToIgnoreCase("Content-Type")==0)
				{
					if(headerValue.substring(0,4).compareToIgnoreCase("text")==0) // text mimetype get converted to strings
					{
						bodytype="UTF-8"; // always utf8 because fuck you :)
					}
					if(headerValue.compareToIgnoreCase("application/json")==0) // json is a string
					{
						bodytype="UTF-8"; // always utf8 because fuck you :)
					}

				}
			}
			
			byte[] content = response.getContent();
			if(bodytype=="BYTE")
			{
				L.rawSet(t,"body",content);
			}
			else
			{
				L.rawSet(t,"body",new String(content,bodytype));
			}
			
			L.push( t );
			return 1;
		}
		catch(IOException e)
		{
			return 0;
		}
//		return 0;
	}
	
}



