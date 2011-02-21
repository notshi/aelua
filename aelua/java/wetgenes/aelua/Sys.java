
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

import java.util.zip.*;

import java.security.MessageDigest;
import java.io.FileInputStream;
import java.io.ByteArrayInputStream;


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
		reg_bin_encode(L,lib);
		reg_md5(L,lib);
		reg_sha1(L,lib);
		reg_hmac_sha1(L,lib);
		reg_bytes_split(L,lib);
		reg_bytes_join(L,lib);
		reg_zip_list(L,lib);
		reg_zip_read(L,lib);
		
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

//
// this probably works
//
	private static String toHex(byte[] digest) {
		StringBuilder sb = new StringBuilder();
		for (byte b : digest) {
			sb.append(String.format("%1$02X", b));
		}
		return sb.toString();
	}
//
// and so does this
//
	private static byte[] fromHex(String s) {
    int len = s.length();
    byte[] data = new byte[len / 2];
    for (int i = 0; i < len; i += 2) {
        data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                             + Character.digit(s.charAt(i+1), 16));
    }
    return data;
}

    private static byte[] BfromS(String t,String s) throws java.io.UnsupportedEncodingException {
		if(t=="hex")
		{
			return fromHex(s);
		}
		else
		if(t=="base64")
		{
			return util.Base64.decode(s);
		}
		else
		{
			return (s.getBytes("UTF-8"));
		}
	}
   	private static String SfromB(String t,byte[] b) throws java.io.UnsupportedEncodingException {
		if(t=="hex")
		{
			return toHex(b);
		}
		else
		if(t=="base64")
		{
			return util.Base64.encodeToString(b,false);
		}
		else
		{
			return new String(b,"UTF-8");
		}
	}
//
// encode a ( string or byte[] ) as hex or base64
//
	public void reg_bin_encode(Lua L,Object lib)
	{
		final Sys _base=this;
		L.rawSet(lib, "bin_encode", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.bin_encode(L); } });
	}
	public int bin_encode(Lua L)
	{
		try
		{
			String t=L.checkString(1);
			byte[] b;
			if( L.isString(L.value(2)) ) { b=L.checkString(2).getBytes("UTF-8"); }
			else { b=(byte[]) L.value(2); }
			L.push( SfromB(t,b) );
			return 1;
		}
   		catch(Exception e) { return 0; }
	}
	
//
// convert string(UTF8) to its md5 hash in hex
//
	public void reg_md5(Lua L,Object lib)
	{
		final Sys _base=this;
		L.rawSet(lib, "md5", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.md5(L); } });
	}
	public int md5(Lua L)
	{
		String t="hex";
		if( L.isString(L.value(2)) ) { t=L.checkString(2); }
		
		try
		{
			String s=L.checkString(1);
			MessageDigest md = MessageDigest.getInstance("MD5");
			byte[] b=md.digest(s.getBytes("UTF-8"));
			
			if(t=="bin") { L.push( b ); } // very raw
			else { L.push( SfromB(t,b) ); } // slightly raw
			return 1;
		}
   		catch(Exception e) { return 0; }
	}
//
// convert string(UTF8) to its sha1 hash in hex
//
	public void reg_sha1(Lua L,Object lib)
	{
		final Sys _base=this;
		L.rawSet(lib, "sha1", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.sha1(L); } });
	}
	public int sha1(Lua L)
	{
		String t="hex";
		if( L.isString(L.value(2)) ) { t=L.checkString(2); }
		
		try
		{
			String s=L.checkString(1);
			MessageDigest md = MessageDigest.getInstance("SHA1");
			byte[] b=md.digest(s.getBytes("UTF-8"));
			
			if(t=="bin") { L.push( b ); } // very raw
			else { L.push( SfromB(t,b) ); } // slightly raw
			return 1;
		}
   		catch(Exception e) { return 0; }
	}
	
//
// convert key(hex) and string(UTF8) into its hmac sha1 hash in hex
//
	public void reg_hmac_sha1(Lua L,Object lib)
	{
		final Sys _base=this;
		L.rawSet(lib, "hmac_sha1", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.hmac_sha1(L); } });
	}
	public int hmac_sha1(Lua L)
	{
		String t="hex";
		if( L.isString(L.value(3)) ) { t=L.checkString(3); }
		
		try
		{
			byte[] key=BfromS(t,L.checkString(1));
			String s=L.checkString(2);
			javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA1");
			mac.init( new javax.crypto.spec.SecretKeySpec(key,"HmacSHA1") );
			byte[] b=mac.doFinal(s.getBytes("UTF-8"));
			
			if(t=="bin") { L.push( b ); } // very raw
			else { L.push( SfromB(t,b) ); } // slightly raw
			return 1;
		}
   		catch(Exception e) { return 0; }
	}


//
// split a (large) bytearray into smaller chunks
//
	public void reg_bytes_split(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "bytes_split", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.bytes_split(L); } });
	}
	public int bytes_split(Lua L)
	{
		Object o=L.value(1);
		
		byte[] bytes = (byte[])o; // the object is bytes
		
		int n=(int)L.checkNumber(2);
		int c=0;
		
		// split the byte array into a table of byte arrays to work with

		LuaTable t=L.createTable(0,0);
		L.push(t);
		
		byte[] bs;
		
		int i=1;
		while( bytes.length > c)
		{
			LuaTable tt=L.createTable(0,0);
			L.rawSetI(t,i++,tt);
			
			if( bytes.length <= c+n ) // all of remaining chunk
			{
				bs=new byte[ bytes.length-c ];
			}
			else // another full chunk
			{
				bs=new byte[ n ];
			}
			
			System.arraycopy(bytes, c, bs, 0, bs.length);

			L.rawSet(tt,"size",bs.length);
			L.rawSet(tt,"data",bs);
	   
			c+=n;
		}
		
		return 1;

	}

//
// split a (large) bytearray into smaller chunks
//
	public void reg_bytes_join(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "bytes_join", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.bytes_join(L); } });
	}
	public int bytes_join(Lua L)
	{
		LuaTable t=(LuaTable)L.value(1);
		int size=0;
		byte[] data;
		int i=1;
		Object o;
		o=L.rawGetI(t,i++);
		while(!L.isNil(o))
		{
			data=(byte[])o;
			size+=data.length;
			o=L.rawGetI(t,i++);
		}
		
		byte[] ret=new byte[ size ];

		int off=0;
		i=1;
		o=L.rawGetI(t,i++);
		while(!L.isNil(o))
		{
			data=(byte[])o;
			System.arraycopy(data, 0, ret, off, data.length);
			off+=data.length;
			o=L.rawGetI(t,i++);
		}
		L.push(ret);
		return 1;
	}

//
// list all the files we can find in a zipfile(bytearray) , this returns a table of data
//
	public void reg_zip_list(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "zip_list", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.zip_list(L); } });
	}
	public int zip_list(Lua L)
	{
		LuaTable t=L.createTable(0,0);
		
		try
		{
			byte[] bytes = (byte[])L.value(1); // the first object is bytes
			
			ByteArrayInputStream bs=new ByteArrayInputStream(bytes);
			ZipInputStream zip=new ZipInputStream(bs);
						
			int i=1;
			ZipEntry entry;
			while((entry = zip.getNextEntry()) != null)
			{
				LuaTable tt=L.createTable(0,0);
				L.rawSetI(t,i++,tt);
				
				L.rawSet(tt,"name",entry.getName());

				L.rawSet(tt,"size", new Double(entry.getSize()) );
			}
		}
   		catch(Exception e) { return 0; }
		
		L.push(t);
		return 1;
	}

//
// read a single file from a zipfile(bytearray) , this returns a bytearray
//
	public void reg_zip_read(Lua L,Object lib)
	{ 
		final Sys _base=this;
		L.rawSet(lib, "zip_read", new LuaJavaCallback(){ Sys base=_base; public int luaFunction(Lua L){ return base.zip_read(L); } });
	}
	public int zip_read(Lua L)
	{
		String name=L.checkString(2); // full file name
		
		try
		{
			byte[] bytes = (byte[])L.value(1); // the first object is bytes
			
			ByteArrayInputStream bs=new ByteArrayInputStream(bytes);
			ZipInputStream zip=new ZipInputStream(bs);
						
			ZipEntry entry;
			while((entry = zip.getNextEntry()) != null)
			{
				if( entry.getName().equals(name) ) // found the file we want
				{
					byte data[] = new byte[(int)entry.getSize()];
					int rem=(int)entry.getSize();
					int off=0;
					int d=0;
					while(rem>0)
					{
						d=zip.read(data,off,rem);
						off+=d;
						rem-=d;
					}
					L.push(data);
					return 1;
				}
			}
		}
   		catch(Exception e) { return 0; }
		
		return 0;
	}

}
