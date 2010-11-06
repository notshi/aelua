
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
  
    public static Lua lua_new() {
		
 		Lua L = new Lua();
		
		BaseLib.open(L);
		PackageLib.open(L);
		StringLib.open(L);
		TableLib.open(L);
		MathLib.open(L);
		OSLib.open(L);
		
		return L;
	}

	public static native void build_bridge() /*-{
		$wnd.lua_new = function() {
			return @wetgenes.jslua.client.JsLua::lua_new();
		}
	}-*/;

}


