
package wetgenes.jslua.client;

import com.google.gwt.core.client.EntryPoint;
import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.ui.Button;
import com.google.gwt.user.client.ui.RootPanel;

import mnj.lua.*;


/**
 * Simple lua hack bindings.
 */

public class JsLua implements EntryPoint {

  public void onModuleLoad() {
	  
/*
    Button b = new Button("Click here bitches", new ClickHandler() {
      public void onClick(ClickEvent event) {
		  
 		Lua L = new Lua();
		
		BaseLib.open(L);
		PackageLib.open(L);
		StringLib.open(L);
		TableLib.open(L);
		MathLib.open(L);
		OSLib.open(L);

		L.loadString(
"		test='poop on you'"+
"		for i=1,10 do"+
"			test=test..' and you'"+
"		end"+
"		","test");
		L.call(0,0);

        Window.alert( (String) L.rawGet(L.getGlobals(), "test") );
      }
    });

    RootPanel.get().add(b);
*/

    
    build_bridge();
  }
  
    public static Lua lua_create() {
		
 		Lua L = new Lua();
		
		BaseLib.open(L);
		PackageLib.open(L);
		StringLib.open(L);
		TableLib.open(L);
		MathLib.open(L);
		OSLib.open(L);
		
		return L;
	}

    public static String lua_get(Lua L, String n) {
		
		return (String) L.rawGet(L.getGlobals(), n);
	}
	
    public static void lua_set(Lua L, String n, String v) {
		
		L.rawSet(L.getGlobals(), n,v);
	}

// just get/set globals and call for pram passing
    public static String lua_dostring(Lua L, String s, String n) {
		
		String r="";
		
		try
		{
			L.loadString(s,n);
			L.call(0,1);
		}
		catch(Exception e)
		{
			r=e.toString();
		}
		
		if( L.type(-1) == L.TSTRING ) // got a string, we can only return strings
		{
			r=(String)L.value(-1);
		}
		
		L.pop(1);
		
		return r;
	}

// load a string, and set the result into the package.preload of the given name
    public static void lua_preloadstring(Lua L, String s, String n) {
		
		Object o=L.rawGet(L.getGlobals(), "package");
		o=L.rawGet(o, "preload");
		
		L.loadString(s,n); // push on stack
		Object f=L.value(-1); // get from stack
		
		L.rawSet(o, n,f); // set loaded string in preload table, ready to execute when required
		
		L.pop(1);
		
	}

// this is a bad interface, it is nothing but hacks for now

	public static native void build_bridge() /*-{
		$wnd.lua_create = $entry(function() {
			return @wetgenes.jslua.client.JsLua::lua_create()();
		});
		$wnd.lua_get = $entry(function(L,n) {
			return @wetgenes.jslua.client.JsLua::lua_get(Lmnj/lua/Lua;Ljava/lang/String;)(L,n);
		});
		$wnd.lua_set = $entry(function(L,n,v) {
			@wetgenes.jslua.client.JsLua::lua_set(Lmnj/lua/Lua;Ljava/lang/String;Ljava/lang/String;)(L,n,v);
		});
		$wnd.lua_dostring = $entry(function(L,s,n) {
			return @wetgenes.jslua.client.JsLua::lua_dostring(Lmnj/lua/Lua;Ljava/lang/String;Ljava/lang/String;)(L,s,n);
		});
		$wnd.lua_preloadstring = $entry(function(L,s,n) {
			@wetgenes.jslua.client.JsLua::lua_preloadstring(Lmnj/lua/Lua;Ljava/lang/String;Ljava/lang/String;)(L,s,n);
		});
	}-*/;

}


