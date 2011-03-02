
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.IOException;
import javax.servlet.http.*;

import java.util.*;
import java.net.*;

import com.google.appengine.api.mail.*;

public class Mail
{
	MailService mail;

	public Mail()
	{
		mail = MailServiceFactory.getMailService();
	}

//
// Open this lib
//	
	public static int open(Lua L)
	{
		LuaTable lib=L.register("wetgenes.aelua.mail.core");
		Mail base=new Mail();
		
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
		L.setField(lib, "wetgenes.aelua.mail.core", new LuaJavaCallback(){ public int luaFunction(Lua L){ return Mail.open(L); } });
	}
	
//
// Add all callable functions and constants to the lib table
//
	int open_lib(Lua L,LuaTable lib)
	{
		reg_send(L,lib);
		
		return 0;
	}

//
// mail
//
	void reg_send(Lua L,Object lib)
	{ 
		final Mail _base=this;
		L.setField(lib, "send", new LuaJavaCallback(){ Mail base=_base; public int luaFunction(Lua L){ return base.send(L); } });
	}
	int send(Lua L)
	{		
		boolean admin=false;
		String s;
		Object o=L.value(1);
		if(!L.isTable(o)) { L.error("mail table required"); }
		LuaTable t=(LuaTable)o;

		try
		{
			MailService.Message msg=new MailService.Message();
			
			o=L.rawGet(t,"to");
			if(L.isString(o))
			{
				s=(String)o;
				if( s.equals("admin") ) // special case admin send
				{
					admin=true;
				}
				else
				{
					msg.setTo(s);
				}
			}
			
			o=L.rawGet(t,"from");
			if(L.isString(o)) { msg.setSender((String)o); }
			
			o=L.rawGet(t,"subject");
			if(L.isString(o)) { msg.setSubject((String)o); }
			
			o=L.rawGet(t,"text");
			if(L.isString(o)) { msg.setTextBody((String)o); }

// the above fields are required and the following fields are optional
			
			o=L.rawGet(t,"html");
			if(L.isString(o)) { msg.setHtmlBody((String)o); }
			
			if(!admin)
			{
				o=L.rawGet(t,"cc");
				if(L.isString(o)) { msg.setCc((String)o); }
				
				o=L.rawGet(t,"bcc");
				if(L.isString(o)) { msg.setBcc((String)o); }
			}
						
			o=L.rawGet(t,"reply");
			if(L.isString(o)) { msg.setReplyTo((String)o); }
			
						
			if(admin)
			{
				mail.sendToAdmins(msg);
			}
			else
			{
				mail.send(msg);
			}
			return 0;
		}
		catch(IOException e)
		{
			return 0;
		}
	}


}



