
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.File;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.FileReader;
import java.io.IOException;
import javax.servlet.http.*;
import java.lang.Thread;

import java.util.*;


public class Sys
{


	public Sys()
	{
	}

//
// Open this lib
//	
	public static int open(Lua L)
	{
		LuaTable lib=L.register("wetgenes.aelua.sys.core");
		Sys base=new Sys();
		
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
		L.setField(lib, "wetgenes.aelua.sys.core", new LuaJavaCallback(){ public int luaFunction(Lua L){ return Sys.open(L); } });
	}
	
//
// Add all callable functions and constants to the lib table
//
	int open_lib(Lua L,LuaTable lib)
	{
		
//		reg_time(L,lib);
//		reg_clock(L,lib);
		reg_sleep(L,lib);
		reg_file_exists(L,lib);
		reg_file_read(L,lib);
		reg_bytes_to_string(L,lib);
		
		return 0;
	}

//
// Return time in seconds since unix epoch, if you are lucky it may be acurate to milliseconds
//
/*
	public void reg_time(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "time", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.time(L); } });
	}
	public int time(Lua L)
	{
		double t=System.currentTimeMillis();
		t=t/1000;
		L.push( t );
		return 1;
	}
*/	
//
// Return time in seconds thats has as much acuracy as possible but should only be compared to other
// values returned from this function. IE it is relative to an arbitary point and may wrap and go teh crazy
// just use it for unimportant benchmark tests
//
/*
	public void reg_clock(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "clock", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.clock(L); } });
	}
	public int clock(Lua L)
	{
		double t=System.nanoTime();
		t=t/1000000000;
		L.push( t );
		return 1;
	}
*/

//
// take a little nap for x seconds
//
	public void reg_sleep(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "sleep", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.sleep(L); } });
	}
	public int sleep(Lua L)
	{
		Double n=L.checkNumber(1);

		try
		{
			Thread.sleep(n.intValue()*1000);
		}
		catch(InterruptedException ex)
		{
		}
		return 0;
	}
	
//
// does this file exist?
//
	public void reg_file_exists(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "file_exists", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.file_exists(L); } });
	}
	public int file_exists(Lua L)
	{
	
		String s=L.checkString(1);
		try
		{
			FileReader f = new FileReader(s);
		}
		catch (IOException e_)
		{
			L.push( false );
			return 1;
		}
		
		L.push( true );
		return 1;
		
	}
	
//
// read this file as a bytearray
//
	public void reg_file_read(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "file_read", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.file_read(L); } });
	}
	public int file_read(Lua L)
	{
		byte[] b;
	
		String s=L.checkString(1);
		try
		{
			b = getBytesFromFile( new File(s) );
		}
		catch (IOException e_)
		{
			L.push( false );
			return 1;
		}
		
		L.push( b );
		return 1;
	}
	
    /**
     * Returns the contents of the file in a byte array
     * @param file File this method should read
     * @return byte[] Returns a byte[] array of the contents of the file
     */
    private static byte[] getBytesFromFile(File file) throws IOException {

        InputStream is = new FileInputStream(file);
//        System.out.println("\nDEBUG: FileInputStream is " + file);

        // Get the size of the file
        long length = file.length();
//        System.out.println("DEBUG: Length of " + file + " is " + length + "\n");

        /*
         * You cannot create an array using a long type. It needs to be an int
         * type. Before converting to an int type, check to ensure that file is
         * not loarger than Integer.MAX_VALUE;
         */
        if (length > Integer.MAX_VALUE) {
            throw new IOException("File is too large to process " + file.getName());
//            return null;
        }

        // Create the byte array to hold the data
        byte[] bytes = new byte[(int)length];

        // Read in the bytes
        int offset = 0;
        int numRead = 0;

         while ( (offset < bytes.length)
                &&
                ( (numRead=is.read(bytes, offset, bytes.length-offset)) >= 0) ) {

            offset += numRead;

        }

        // Ensure all the bytes have been read in
        if (offset < bytes.length) {
            throw new IOException("Could not completely read file " + file.getName());
        }

        is.close();
        return bytes;

    }
//
// convert bytearray to a string
//
	public void reg_bytes_to_string(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "bytes_to_string", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.bytes_to_string(L); } });
	}
	public int bytes_to_string(Lua L)
	{
		try
		{
			Object o=L.value(1);
			if( L.isString(o) ) // already a string so return as is
			{
				L.push(o);
				return 1;
			}
			byte[] bytes = (byte[])o; // the object is bytes
			L.push( new String(bytes,"UTF-8") ); // convert to a string
			return 1;
		}
		catch(IOException e)
		{
			return 0;
		}
	}
}
