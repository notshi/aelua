
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.InputStream;
import java.io.IOException;
import java.io.BufferedReader;
import java.io.InputStreamReader;

import javax.servlet.ServletException;
import javax.servlet.http.*;

import org.apache.commons.fileupload.FileItemStream;
import org.apache.commons.fileupload.FileItemIterator;
import org.apache.commons.fileupload.servlet.ServletFileUpload;

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
		reg_set_header(L,lib);
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
		
		
		LuaTable posts=L.createTable(0,0);	// create posts table
		L.rawSet(lib, "posts", posts );
		
		try
		{
			ServletFileUpload upload = new ServletFileUpload();
			FileItemIterator iterator = upload.getItemIterator(req);
			
			while (iterator.hasNext())
			{
				FileItemStream item = iterator.next();
				InputStream stream = item.openStream();

				if (item.isFormField())
				{
					String line;
					
					StringBuilder sb = new StringBuilder();
					
					BufferedReader reader = new BufferedReader(new InputStreamReader(stream, "UTF-8"));
					
					while ((line = reader.readLine()) != null)
					{
						sb.append(line).append("\n");
					}

					String data=sb.toString();
					
					L.rawSet( posts , item.getFieldName() , data );
					
				}
				else
				{
					/*
						log.warning("Got an uploaded file: " + item.getFieldName() +
						", name = " + item.getName());

						// You now have the filename (item.getName() and the
						// contents (which you can read from stream).  Here we just
						// print them back out to the servlet output stream, but you
						// will probably want to do something more interesting (for
						// example, wrap them in a Blob and commit them to the
						// datastore).
						int len;
						byte[] buffer = new byte[8192];
						while ((len = stream.read(buffer, 0, buffer.length)) != -1) {
						res.getOutputStream().write(buffer, 0, len);
					*/
				}
			}
		}
		catch (Exception ex) 
		{
//			throw new ServletException(ex);
//			L.error(ex.toString());
//			return 0;
		}
	
		LuaTable gets=L.createTable(0,0);	// create gets table
		L.rawSet(lib, "gets", gets );
		
		for( java.util.Enumeration e = req.getParameterNames() ; e.hasMoreElements() ; )
		{
			String name = (String)e.nextElement();
			L.rawSet( gets , name , req.getParameter(name) );
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
// Set a header response
//
	public void reg_set_header(Lua L,Object lib)
	{ 
		final Srv _base=this;
		L.rawSet(lib, "set_header", new LuaJavaCallback(){ Srv base=_base; public int luaFunction(Lua L){ return base.set_header(L); } });
	}
	public int set_header(Lua L)
	{
		String si=L.checkString(1);
		String sv=L.checkString(2);
		resp.setHeader(si,sv);
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
		if(! L.isTable(L.value(1))) { L.error("cookie must be a table"); }
		
		LuaTable cookie=(LuaTable)L.value(1);
		
		Object name=L.rawGet(cookie,"name");
		Object value=L.rawGet(cookie,"value");
		Object domain=L.rawGet(cookie,"domain");
		Object path=L.rawGet(cookie,"path");
		Object live=L.rawGet(cookie,"live");
		
		Cookie c=new Cookie(L.toString(name),L.toString(value));
		
		if( L.isString(domain) ) { c.setDomain(L.toString(domain)); }
		if( L.isString(path) )   { c.setPath  (L.toString(path));   }
		if( L.isNumber(live) )   { c.setMaxAge((int)L.toNumber(live));   }
		
		resp.addCookie(c);
		
		return 0;
	}
	
	
}



