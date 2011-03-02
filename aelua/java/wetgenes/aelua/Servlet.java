package wetgenes.aelua;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.FileReader;

import java.util.logging.Logger;

import java.io.IOException;
import javax.servlet.http.*;


import mnj.lua.*;

import wetgenes.aelua.Srv;


public class Servlet extends HttpServlet {

// this is hacks to cope with appengine going screwy, lets hope it works better with reuse of lua state?
// ok looks like only the local debug engine will handle multiple requests at the same time
// so all the multiple state stuff is not really used on the live instances
// as when run on the live server it just creates a new instance.

static Lua[] Lbase=new Lua[16]; // we keep one state, building it as needed
static int[] runcount=new int[16]; // count number of requests and reload every 1000? just in case
static boolean[] running=new boolean[16]; // this will get stuck on true if we hit a bad exception?

	public void serv(HttpServletRequest req, HttpServletResponse resp)
			throws IOException {
				
		int idx=0;
		while( idx<running.length )
		{
			if(running[idx]==false) { break; } // reuse
			idx++;
		} // find free slot?
			
		try
		{
			
			Lua L=null;
			if( idx<running.length )
			{
				L=Lbase[idx];
				running[idx]=true;
				runcount[idx]++; // keep count
				if(runcount[idx]>1000)
				{
					Lbase[idx]=null; // force allocate a new state every X requests
				}
			}
			
			
			if(L==null) // need to create new L, this is a major disk hit and seems to be problematic sometimes...
			{
	Logger.getLogger("").info("creating state "+idx);


				L = new Lua();
				if( idx<running.length )
				{
					runcount[idx]=0;
					if(Lbase[idx]==null) { Lbase[idx]=L; } // new master
				}
				
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
				Fetch.preload(L);
				Mail.preload(L);
				
				L.loadFile("lua/init.lua");
				L.call(0,0);
			}
			
			L.push( L.rawGet(L.getGlobals(), "serv") );
			Srv srv=new Srv(req,resp,this); // our response srv, should not be global, created per request
			srv.push_lib(L);
			L.call(1,0);
		
			if( idx<running.length )
			{
				running[idx]=false;
			}
		}
		catch(RuntimeException e)
		{
			if( idx<running.length )
			{
				running[idx]=false;
				Lbase[idx]=null;
			}
			
			throw(e);
		}
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
	
// clear all lua cache so we load it all again
	public void reloadcache()
	{
		for(int i=0;i<16;i++)
		{
			Lbase[i]=null;
			runcount[i]=0;
			running[i]=false;
		}
	}
}
