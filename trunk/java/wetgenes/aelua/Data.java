
package wetgenes.aelua;


import mnj.lua.LuaJavaCallback;
import mnj.lua.LuaTable;
import mnj.lua.Lua;

import java.io.IOException;
import javax.servlet.http.*;

import java.util.*;

import com.google.appengine.api.datastore.*;

public class Data
{

	DatastoreService ds;
	Transaction trans;

	public Data()
	{
		ds = DatastoreServiceFactory.getDatastoreService();
	}

//
// Open this lib
//	
	public static int open(Lua L)
	{
		LuaTable lib=L.register("wetgenes.aelua.data.core");
		Data base=new Data();
		
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
		L.setField(lib, "wetgenes.aelua.data.core", new LuaJavaCallback(){ public int luaFunction(Lua L){ return Data.open(L); } });
	}
	
//
// Add all callable functions and constants to the lib table
//
	int open_lib(Lua L,LuaTable lib)
	{
	
		reg_keystr(L,lib);
		reg_keyinfo(L,lib);
		
		reg_del(L,lib);
		reg_put(L,lib);
		reg_get(L,lib);
		reg_query(L,lib);
		
		reg_transaction(L,lib);
		
		return 0;
	}

//
// begin
// rollback
// commit
//
// a transaction group
//
// we only suport one transaction at a time...
//
	void reg_transaction(Lua L,Object lib)
	{ 
		final Data _base=this;
		L.setField(lib, "transaction", new LuaJavaCallback(){ Data base=_base; public int luaFunction(Lua L){ return base.transaction(L); } });
	}
	int transaction(Lua L)
	{
		Object o=L.value(1); // command
		if(!L.isString(o)) { L.error("transaction command must be a string"); }
		String s=L.toString(o);
		
		if(s=="begin")
		{
			if(trans!=null) { L.error("nested transactions not suported"); }
			trans=ds.beginTransaction();
			L.push( Boolean.TRUE );
			return 1;
		}
		else
		if(s=="rollback")
		{
			trans.rollback();
			trans=null;
			L.push( Boolean.TRUE );
			return 1;
		}
		else
		if(s=="commit")
		{
			trans.commit();
			trans=null;
			L.push( Boolean.TRUE );
			return 1;
		}
		else
		{
			L.error("unknown transaction command");
		}
		
		return 0;
	}
	
	
//
// Create a key informaton table from a key string
// this does not recurse, it just stores its parent as a key string
//
	void reg_keyinfo(Lua L,Object lib)
	{ 
		final Data _base=this;
		L.setField(lib, "keyinfo", new LuaJavaCallback(){ Data base=_base; public int luaFunction(Lua L){ return base.keyinfo(L); } });
	}
	int keyinfo(Lua L)
	{
		Object o1=L.value(1); // keystr
		if(!L.isString(o1)) { L.error("key must be a string"); }
		
		Key k=KeyFactory.stringToKey((String)o1);
		
		LuaTable t=L.newTable();
		
		keytab_fill(L , k , t);
	
		L.push( t );
		return 1;
	}
	void keytab_fill(Lua L , Key k , LuaTable t)
	{
		if(k.getParent()!=null) { L.rawSet(t,"parent",KeyFactory.keyToString(k.getParent())); }
		
		if(k.getKind()!=null) { L.rawSet(t,"kind",k.getKind()); }
		
		if(k.getName()!=null) { L.rawSet(t,"id",(String)k.getName());   }
		else				  { L.rawSet(t,"id",(double)k.getId());     }
		
		L.rawSet(t,"key",KeyFactory.keyToString(k));
	}
	
//
// Create a key string, keys are passed around as these special websafe strings
//
	void reg_keystr(Lua L,Object lib)
	{ 
		final Data _base=this;
		L.setField(lib, "keystr", new LuaJavaCallback(){ Data base=_base; public int luaFunction(Lua L){ return base.keystr(L); } });
	}
	int keystr(Lua L)
	{

		Object kind   = L.value(1); // kind (str)
		Object id     = L.value(2); // id (int/str)
		Object parent = L.value(3); // parent (str)
		
		Key k=keystr_makekey(L,kind,id,parent);
		
		if(k==null) { return 0; }
		
		L.push( KeyFactory.keyToString(k) );
		return 1;
	}
	Key keystr_makekey(Lua L,Object kind,Object id,Object parent)
	{
		Key k=null;
		Key p;
		
		if(!L.isString(kind)) { L.error("key kind must be a string"); }
		
		if(!L.isNil(id))
		{
			if(L.isNumber(id))
			{
				if(!L.isNil(parent))
				{
					if(!L.isString(parent)) { L.error("key parent must be a string"); }
					p=KeyFactory.stringToKey((String)(parent));
					k=KeyFactory.createKey( p , ((String)(kind)) , ((Double)(id)).intValue() );
				}
				else // no parent
				{
					k=KeyFactory.createKey( ((String)(kind)) , ((Double)(id)).intValue() );
				}
			}
			else
			if(L.isString(id))
			{
				if(!L.isNil(parent))
				{
					if(!L.isString(parent)) { L.error("key parent must be a string"); }
					p=KeyFactory.stringToKey((String)(parent));
					k=KeyFactory.createKey( p , ((String)(kind)) , ((String)(id)) );
				}
				else // no parent
				{
					k=KeyFactory.createKey( ((String)(kind)) , ((String)(id)) );
				}
			}
			else { L.error("key id must be a string or number : "+L.type(id) ); }
		}
		else // no key
		{
			L.error("key id must be a string or number");
		}
	
		return k;
	}
	
//
// Lua data put function, writes an entity to storage
//
	void reg_put(Lua L,Object lib)
	{ 
		final Data _base=this;
		L.setField(lib, "put", new LuaJavaCallback(){ Data base=_base; public int luaFunction(Lua L){ return base.put(L); } });
	}
	int put(Lua L)
	{
		Object o;
		
		o=L.value(1);
		if(!L.isTable(o)) { L.error("entity must be a table"); }
		LuaTable ent=(LuaTable)o;

		o=L.rawGet(ent, "props");
		if(!L.isTable(o)) { L.error("entity.props must be a table"); }
		LuaTable props=(LuaTable)o;
		
		Object key=L.rawGet(ent, "key");
		Key k;
		Entity e=null;
		
		if(L.isString(key)) // forced key
		{
			k=KeyFactory.stringToKey((String)(key));
			e=new Entity(k);
		}
		else
		if(L.isTable(key)) // build a key, possibly without an id
		{
			
			Object kind=L.rawGet(key, "kind");
			Object id=L.rawGet(key, "id");
			Object parent=L.rawGet(key, "parent");

			if(L.isNil(id)) // auto id on put
			{
				if(L.isString(parent)) // key heirachy
				{
					Key p=KeyFactory.stringToKey((String)(parent));
					
					e=new Entity( (String)kind , p );
				}
				else
				{
					e=new Entity( (String)kind );
				}
			}
			else
			{
				k=keystr_makekey(L,kind,id,parent);
				e=new Entity(k);
			}
		}
		else
		{
			L.error("entity.key is missing");
		}
		
		Enumeration t = props.keys();
 
		while(t.hasMoreElements())
		{
			Object i=t.nextElement();
			Object v=props.getlua(i);
			
			// convert byte array into blob
			if(v instanceof byte[] )
			{
				e.setProperty((String)i, new Blob( (byte[])v ) );
			}
			else
			{
				e.setProperty((String)i,v);
			}
		}
		
		if(trans==null)
		{
			ds.put(e); // actually write it
		}
		else
		{
			ds.put(trans,e); // actually write it
		}
		
		// return a keystring since it may have just been created
		L.push( KeyFactory.keyToString( e.getKey() ) );

		return 1;
	}
	
//
// Create a Lua entity copy
//
	LuaTable luaentity_create(Lua L, Entity e)
	{
		LuaTable t=L.newTable(); 
		
		luaentity_fill(L,t,e);
		
		return t;
	}
//
// Fill in the data of a Lua entity copy
//
	void luaentity_fill(Lua L, LuaTable t, Entity e)
	{
		Object o;
		
		Key k=e.getKey(); // the entity key?
		
		LuaTable key=L.newTable(); 
		L.rawSet(t, "key",key);
		
		keytab_fill(L , k , key);
		
		LuaTable props=L.newTable(); 
		L.rawSet(t, "props",props);
		
		for( Iterator it=e.getProperties().keySet().iterator() ; it.hasNext() ;)
		{
			Object i=it.next();
			if(!L.isNil(i))
			{
				Object v=e.getProperty((String)i);
				if(v instanceof Blob)
				{
					L.rawSet(props,(String)i,((Blob)v).getBytes());
				}
				else
				{
					L.rawSet(props,(String)i,v);
				}
			}
		}
		
	}
	
//
// Get an entity of the given key and return its data
//
	void reg_get(Lua L,Object lib)
	{ 
		final Data _base=this;
		L.setField(lib, "get", new LuaJavaCallback(){ Data base=_base; public int luaFunction(Lua L){ return base.get(L); } });
	}
	int get(Lua L)
	{
		Object o;
		
		o=L.value(1);
		if(!L.isTable(o)) { L.error("entity must be a table"); }
		LuaTable ent=(LuaTable)o;

		o=L.rawGet(ent, "key");
		if(!L.isTable(o)) { L.error("entity.key must be a table"); }
		LuaTable key=(LuaTable)o;
		
		Key k=keystr_makekey(L,L.rawGet(key, "kind"),L.rawGet(key, "id"),L.rawGet(key, "parent"));

		Entity e;
		
		try
		{
			if(trans==null)
			{
				e=ds.get(k);
			}
			else
			{
				e=ds.get(trans,k);
			}
		}
		catch(EntityNotFoundException ex)
		{
			return 0;
		}
		
		luaentity_fill(L,ent,e);
		
		L.push(ent); // return ourselves	  
		return 1;
	}
	
//
// Delete an entity of the given key
//
	void reg_del(Lua L,Object lib)
	{ 
		final Data _base=this;
		L.setField(lib, "del", new LuaJavaCallback(){ Data base=_base; public int luaFunction(Lua L){ return base.del(L); } });
	}
	int del(Lua L)
	{
		Object o;
		
		o=L.value(1);
		if(!L.isTable(o)) { L.error("key must be a table"); }
		LuaTable key=(LuaTable)o;
		
		Key k=keystr_makekey(L,L.rawGet(key, "kind"),L.rawGet(key, "id"),L.rawGet(key, "parent"));

		try
		{
			if(trans==null)
			{
				ds.delete(k);
			}
			else
			{
				ds.delete(trans,k);
			}
		}
		catch(IllegalStateException ex)
		{
			return 0;
		}
		
		L.push(o); // return the key used on success
		return 1;
	}
	
//
// Query a list of entitys which are all converted to lua tables
//
// probably should not do this with large chunks of data
//
	void reg_query(Lua L,Object lib)
	{ 
		final Data _base=this;
		L.setField(lib, "query", new LuaJavaCallback(){ Data base=_base; public int luaFunction(Lua L){ return base.query(L); } });
	}
	int query(Lua L)
	{
		int i;
		LuaTable v;
		LuaTable t;
		
		Object o;
		
		int limit=1000;
		int offset=0;
		Cursor cursor=null;
		String kind=null;
		Key parent=null;
		
		o=L.value(1);
		if(!L.isTable(o)) { L.error("query options must be a table"); }
		LuaTable opt=(LuaTable)o;
		
		o=opt.getlua("cursor"); if(L.isString(o)) { cursor=Cursor.fromWebSafeString((String)o); }
		o=opt.getlua("parent"); if(L.isString(o)) { parent=KeyFactory.stringToKey((String)o); }
		o=opt.getlua("kind");   if(L.isString(o)) { kind=(String)o; }
		o=opt.getlua("limit");  if(L.isNumber(o)) { limit =((Double)o).intValue(); }
		o=opt.getlua("offset"); if(L.isNumber(o)) { offset=((Double)o).intValue(); }
		
		Query q;
		
		if(kind==null)
		{
			if(parent==null)
			{
				q = new Query();
			}
			else
			{
				q = new Query(parent);
			}
		}
		else
		{
			if(parent==null)
			{
				q = new Query(kind);
			}
			else
			{
				q = new Query(kind,parent);
			}
		}

		i=0;
		do
		{
			o=opt.getnum(++i);
			
			if(L.isTable(o))
			{
				v=(LuaTable)o;
				if( ((String)v.getnum(1))=="filter" )
				{
					String sa=((String)v.getnum(2));
					String sb=((String)v.getnum(3));
					Object sc=v.getnum(4);
					
					if(sb=="<") { q.addFilter(sa,Query.FilterOperator.LESS_THAN,sc); }
					else
					if(sb==">") { q.addFilter(sa,Query.FilterOperator.GREATER_THAN,sc); }
					else
					if(sb=="<=") { q.addFilter(sa,Query.FilterOperator.LESS_THAN_OR_EQUAL ,sc); }
					else
					if(sb==">=") { q.addFilter(sa,Query.FilterOperator.GREATER_THAN_OR_EQUAL ,sc); }
					else
					if(sb=="==") { q.addFilter(sa,Query.FilterOperator.EQUAL ,sc); }
					else
					if(sb=="!=") { q.addFilter(sa,Query.FilterOperator.NOT_EQUAL ,sc); }
				}
				else
				if( ((String)v.getnum(1))=="sort" )
				{
					String sa=((String)v.getnum(2));
					String sb=((String)v.getnum(3));
					if(sb==">") { q.addSort(sa,Query.SortDirection.ASCENDING); }
					else
					if(sb=="<") { q.addSort(sa,Query.SortDirection.DESCENDING); }
				}
			}
		}
		while(!L.isNil(o));
		
		
		t=L.newTable();		
		L.rawSet(t,"code", q.toString() );
		
		try
		{
			FetchOptions f=FetchOptions.Builder.withLimit(limit).offset(offset);
			if( cursor!=null ) { f.cursor(cursor); } // passed in a cursor?
			
			PreparedQuery pq;
			
			if(trans==null)
			{
				pq=ds.prepare(q);
			}
			else
			{
				pq=ds.prepare(trans,q);
			}
			
			QueryResultList ql=pq.asQueryResultList(f);
			
			L.rawSet(t,"count", new Double( (pq.countEntities()) ) );
			
			i=1;
			for(Object e : ql )
			{
				L.rawSetI(t,i, luaentity_create(L,(Entity)e) );
				i=i+1;
			}
			L.rawSet(t,"cursor", ql.getCursor().toWebSafeString() );
		}
		catch(DatastoreNeedIndexException ex)
		{
			L.rawSet(t,"error", ex.toString() );
		}


		L.push(t); // return list of expanded results
		return 1;
	}
	
}



