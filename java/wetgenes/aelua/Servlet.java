package wetgenes.aelua;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.FileReader;


import java.io.IOException;
import javax.servlet.http.*;


import mnj.lua.*;

import wetgenes.aelua.Core;


public class Servlet extends HttpServlet {
	
	public void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws IOException {
	
		Lua L = new Lua();
		
		BaseLib.open(L);
		PackageLib.open(L);
		StringLib.open(L);
		TableLib.open(L);
		MathLib.open(L);
		OSLib.open(L);
		
		Log.preload(L);
		Data.preload(L);
		User.preload(L);
		
		Core core=new Core(req,resp); // our response core, shouldnt be global

		L.loadFile("lua/serv.lua");
		L.call(0,0);
		
		L.push( L.rawGet(L.getGlobals(), "serv") );
		core.push_lib(L);
		L.call(1,0);
	
		
	}
}