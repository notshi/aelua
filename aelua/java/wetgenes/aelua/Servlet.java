package wetgenes.aelua;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.FileReader;


import java.io.IOException;
import javax.servlet.http.*;


import mnj.lua.*;

import wetgenes.aelua.Srv;


public class Servlet extends HttpServlet {
	
	public void serv(HttpServletRequest req, HttpServletResponse resp)
			throws IOException {
			
		Lua L = new Lua();
		
		BaseLib.open(L);
		PackageLib.open(L);
		StringLib.open(L);
		TableLib.open(L);
		MathLib.open(L);
		OSLib.open(L);
		
		Sys.preload(L);
		Log.preload(L);
		Img.preload(L);
		Data.preload(L);
		Cache.preload(L);
		User.preload(L);
		
		Srv srv=new Srv(req,resp); // our response srv, should not be global

		L.loadFile("lua/init.lua");
		L.call(0,0);
		
		L.push( L.rawGet(L.getGlobals(), "serv") );
		srv.push_lib(L);
		L.call(1,0);
	
	}
	
// send everything thrugh the serv function, we will sort it later

	public void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws IOException {
	
		serv(req,resp);
	}
	public void doPost(HttpServletRequest req, HttpServletResponse resp)
			throws IOException {
	
		serv(req,resp);
	}
	public void doPut(HttpServletRequest req, HttpServletResponse resp)
			throws IOException {
	
		serv(req,resp);
	}
	public void doDelete(HttpServletRequest req, HttpServletResponse resp)
			throws IOException {
	
		serv(req,resp);
	}
}
