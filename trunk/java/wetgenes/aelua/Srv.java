
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

		 
		reg_print(L,lib);
		reg_mimetype(L,lib);
		reg_time(L,lib);
		reg_nanotime(L,lib);
		
		s=req.getRequestURL().toString();
		if(s!=null) { L.setField(lib, "url", s ); }
		
		s=req.getQueryString();
		if(s!=null) { L.setField(lib, "urlq", s ); }
		
		return 1;
	}

	public void reg_print(Lua L,Object lib)
	{ 
		final Srv _base=this;
		L.setField(lib, "print", new LuaJavaCallback(){ Srv base=_base; public int luaFunction(Lua L){ return base.print(L); } });
	}
	public int print(Lua L)
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
	
	public void reg_mimetype(Lua L,Object lib)
	{ 
		final Srv _base=this;
		L.setField(lib, "mimetype", new LuaJavaCallback(){ Srv base=_base; public int luaFunction(Lua L){ return base.mimetype(L); } });
	}
	public int mimetype(Lua L)
	{
		String s=L.checkString(1);
		resp.setContentType(s);
		return 0;
	}

	
	public void reg_time(Lua L,Object lib)
	{ 
		final Srv _base=this;
		L.setField(lib, "time", new LuaJavaCallback(){ Srv base=_base; public int luaFunction(Lua L){ return base.time(L); } });
	}
	public int time(Lua L)
	{
		double t=System.currentTimeMillis();
		t=t/1000;
		L.push( t );
		return 1;
	}
	
	public void reg_nanotime(Lua L,Object lib)
	{ 
		final Srv _base=this;
		L.setField(lib, "nanotime", new LuaJavaCallback(){ Srv base=_base; public int luaFunction(Lua L){ return base.nanotime(L); } });
	}
	public int nanotime(Lua L)
	{
		double t=System.nanoTime();
		t=t/1000000000;
		L.push( t );
		return 1;
	}
	
}



