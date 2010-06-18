
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

import org.apache.commons.io.IOUtils;

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
		reg_redirect(L,lib);
		
		L.rawSet(lib,"method",req.getMethod());
		
		L.rawSet(lib,"ip",req.getRemoteAddr());
		
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
		
		LuaTable uploads=L.createTable(0,0);	// create uploads table
		L.rawSet(lib, "uploads", uploads );
		
		LuaTable gets=L.createTable(0,0);	// create gets table
		L.rawSet(lib, "gets", gets );
		
		LuaTable vars=L.createTable(0,0);	// create merged vars table
		L.rawSet(lib, "vars", gets );
		
		for( java.util.Enumeration e = req.getParameterNames() ; e.hasMoreElements() ; )
		{
			String name = (String)e.nextElement();
//
// looks like java is being helpful, unfortunatly it merges gets and posts
// use enctype="multipart/form-data" in your forms if you want data to turn up in the posts table
// a normal post will just turn up in gets since im not sure if it was real post data
// data will only be placed in posts if I'm sure it was actual post data
// gets are easier to fake, eg cross site img urls, so its kind of important to know the diference
//
// Java is great, all hail java and its standard standards! *rolls eyes*
//

/*
 			if(req.getMethod()=="POST")
			{
				L.rawSet( posts , name , req.getParameter(name) );
				L.rawSet( vars , name , req.getParameter(name) );
			}
			else
*/
			{
				L.rawSet( gets , name , req.getParameter(name) );
				L.rawSet( vars , name , req.getParameter(name) ); // merge gets and posts into vars
			}
		}
		
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
					L.rawSet( vars , item.getFieldName() , data ); // posts will overide gets in vars
					
				}
				else
				{
					LuaTable tab=L.createTable(0,0);	// uploaded info tab
					
					L.rawSet( uploads , item.getFieldName() , tab );
					
					byte[] buffer = IOUtils.toByteArray(stream);
					
					L.rawSet( tab , "name" , item.getName() );
					L.rawSet( tab , "data" , buffer ); // grab file
					
					L.rawSet( tab , "size" , (double)buffer.length );
					
				}
			}
		}
		catch (Exception ex) 
		{
//			throw new ServletException(ex);
//			L.error(ex.toString());
//			return 0;
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
			Object o=L.value(1);
			if(L.isString(o))
			{
				resp.getWriter().println((String)o);
			}
			else // output a bytearray
			{
				resp.getOutputStream().write( (byte[])o );
			}
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
	
	
//
// Set a header response
//
	public void reg_redirect(Lua L,Object lib)
	{ 
		final Srv _base=this;
		L.rawSet(lib, "redirect", new LuaJavaCallback(){ Srv base=_base; public int luaFunction(Lua L){ return base.redirect(L); } });
	}
	public int redirect(Lua L)
	{
		String s=L.checkString(1);
		try
		{
			resp.sendRedirect(s);
		}
		catch( IOException ex )
		{
			L.push(false);
			return 1;
		}
		L.push(true);
		return 1;
	}
	
	
}



