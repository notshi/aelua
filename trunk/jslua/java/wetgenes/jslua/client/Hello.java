
package wetgenes.jslua.client;

import com.google.gwt.core.client.EntryPoint;
import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.ui.Button;
import com.google.gwt.user.client.ui.RootPanel;

import mnj.lua.*;


/**
 * HelloWorld application.
 */

public class Hello implements EntryPoint {

  public void onModuleLoad() {
    Button b = new Button("Click here bitches", new ClickHandler() {
      public void onClick(ClickEvent event) {
		  
 		Lua L = new Lua();
		
		BaseLib.open(L);
		PackageLib.open(L);
		StringLib.open(L);
		TableLib.open(L);
		MathLib.open(L);
		OSLib.open(L);

		L.loadString("test='poop on you'","test");
		L.call(0,0);

        Window.alert( (String) L.rawGet(L.getGlobals(), "test") );
      }
    });

    RootPanel.get().add(b);
  }
}


