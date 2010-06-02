
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.IOException;
import javax.servlet.http.*;

public class Srv
{

	HttpServletRequest req;
	HttpServletResponse resp;

	public Srv(HttpServletRequest _req, HttpServletResponse _resp )
	{
		req=_req;
		resp=_resp;
		
	}

	public int push_lib(Lua L)
	{
		String s;
			
		LuaTable lib=L.createTable(0,0);
		L.push(lib);

		 
		reg_put(L,lib);
		reg_set_mimetype(L,lib);
		reg_set_cookie(L,lib);
		
		L.rawSet(lib,"method",req.getMethod());
		
		s=req.getRequestURL().toString();
		if(s!=null) { L.rawSet(lib, "url", s ); } // the url requested
		
		s=req.getQueryString();
		if(s!=null) { L.rawSet(lib, "query", s ); } // the query string
		
		
		LuaTable cookies=L.createTable(0,0);	// create cookies table
		L.rawSet(lib, "cookies", cookies );
		
		if(req.getCookies()!=null) // may be null?
		{
			for(Cookie c : req.getCookies() ) // just fill in basic cookie values
			{
				L.rawSet( cookies , c.getName() , c.getValue() );
			}
			
		}
		
		LuaTable headers=L.createTable(0,0);	// create cookies table
		L.rawSet(lib, "headers", headers );
		
		
		for( java.util.Enumeration e = req.getHeaderNames() ; e.hasMoreElements() ; )
		{
			String name = (String)e.nextElement();
			L.rawSet( headers , name , req.getHeader(name) );
		}
		
		return 1;
	}

//
// Write out a response string or data
//
	public void reg_put(Lua L,Object lib)
	{ 
		final Srv _base=this;
		L.rawSet(lib, "put", new LuaJavaCallback(){ Srv base=_base; public int luaFunction(Lua L){ return base.put(L); } });
	}
	public int put(Lua L)
	{
		try
		{
			String s=L.checkString(1);
			resp.getWriter().println(s);
			return 0;
		}
		catch(IOException e)
		{
			L.error(e.toString());
			return 0;
		}
	}
	
//
// Set the mimetype response
//
	public void reg_set_mimetype(Lua L,Object lib)
	{ 
		final Srv _base=this;
		L.rawSet(lib, "set_mimetype", new LuaJavaCallback(){ Srv base=_base; public int luaFunction(Lua L){ return base.set_mimetype(L); } });
	}
	public int set_mimetype(Lua L)
	{
		String s=L.checkString(1);
		resp.setContentType(s);
		return 0;
	}

//
// Set a browserside cookie
//
	public void reg_set_cookie(Lua L,Object lib)
	{ 
		final Srv _base=this;
		L.rawSet(lib, "set_cookie", new LuaJavaCallback(){ Srv base=_base; public int luaFunction(Lua L){ return base.set_cookie(L); } });
	}
	public int set_cookie(Lua L)
	{
		return 0;
	}
	
	
}



