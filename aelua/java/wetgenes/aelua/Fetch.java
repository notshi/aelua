
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.IOException;
import javax.servlet.http.*;

import java.util.*;
import java.net.*;

import com.google.appengine.api.urlfetch.*;
import static com.google.appengine.api.urlfetch.FetchOptions.Builder.*;

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
		reg_post(L,lib);
		
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
			URL url = new URL(s);
			HTTPRequest req=new HTTPRequest(url,HTTPMethod.GET,
				com.google.appengine.api.urlfetch.FetchOptions.Builder.followRedirects().setDeadline(10.0) );
			HTTPResponse response = fetcher.fetch(req);
			
			return response_results(L,response);
		}
		catch(IOException e)
		{
			L.pushNil();
			L.pushString( e.toString() );
			return 2;
		}
	}

//
// A simple and blocking url post
//
	void reg_post(Lua L,Object lib)
	{ 
		final Fetch _base=this;
		L.setField(lib, "post", new LuaJavaCallback(){ Fetch base=_base; public int luaFunction(Lua L){ return base.post(L); } });
	}
	int post(Lua L)
	{
		Object o;
		
		String s=L.checkString(1); // url to fetch
		
		o=L.value(2);
		if(!L.isTable(o)) { L.error("header must be a table"); }
		LuaTable t2=(LuaTable)o;
		
		String s3=L.checkString(3); // post data payload
		
		try
		{
			
			URL url = new URL(s);
			HTTPRequest req=new HTTPRequest(url,HTTPMethod.POST,
				com.google.appengine.api.urlfetch.FetchOptions.Builder.followRedirects().setDeadline(10.0) );
				
 			
			Enumeration t = t2.keys();
	 
			while(t.hasMoreElements())
			{
				String i=L.toString(t.nextElement());
				String v=L.toString(t2.getlua(i));
				
				req.setHeader( new HTTPHeader(i,v) );
				
//req.setHeader( new HTTPHeader("Content-Type","x-www-form-urlencoded; charset=utf-8") );
			
			}


			req.setPayload( s3.getBytes("UTF-8") );
			
			HTTPResponse response = fetcher.fetch(req);
			
			return response_results(L,response);
			
		}
		catch(IOException e)
		{
			L.pushNil();
			L.pushString( e.toString() );
			return 2;
		}
	}


//
// handle the results
//
	int response_results(Lua L,HTTPResponse response)
	{ 
		try
		{
			LuaTable t=L.newTable();
			
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
					if(headerValue.length()>=4)
					if(headerValue.substring(0,4).compareToIgnoreCase("text")==0) // text mimetype get converted to strings
					{
						bodytype="UTF-8"; // always utf8 because fuck you :)
					}
					if(headerValue.length()>=11)
					if(headerValue.substring(0,11).compareToIgnoreCase("application")==0) // json is a string
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
			L.pushNil();
			L.pushString( e.toString() );
			return 2;
		}
	}

}



