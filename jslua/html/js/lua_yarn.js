
var L; // this will be our lua state

// lua has no fileaccess for module loading
// so instead all modulefiles must be preloaded and shoved into package.preload
// a little bit harsh for requesting lots of small files
// but it will do for now

var preload_lua_list=[

	{file:"luac/yarn/init.lua",			name:"yarn"},
	{file:"luac/yarn/attr.lua",			name:"yarn.attr"},
	{file:"luac/yarn/cell.lua",			name:"yarn.cell"},
	{file:"luac/yarn/chardata.lua",		name:"yarn.chardata"},
	{file:"luac/yarn/charfight.lua",	name:"yarn.charfight"},
	{file:"luac/yarn/char.lua",			name:"yarn.char"},
	{file:"luac/yarn/itemdata.lua",		name:"yarn.itemdata"},
	{file:"luac/yarn/item.lua",			name:"yarn.item"},
	{file:"luac/yarn/level.lua",		name:"yarn.level"},
	{file:"luac/yarn/map.lua",			name:"yarn.map"},
	{file:"luac/yarn/menu.lua",			name:"yarn.menu"},
	{file:"luac/yarn/room.lua",			name:"yarn.room"}

];
var preload_lua_idx=0;
var preload_lua_func;

preload_lua_func=function(data){
	
var pct=0;

	var v=preload_lua_list[preload_lua_idx];
	
	pct=Math.floor( 100 * ((preload_lua_idx*2)+(data?1:0))/((preload_lua_list.length-1)*2) );

$("#displayhack").html("<pre class='prehack'>\n\nPlease remain calm,\n\tyarn is loading : "+pct+"%\n\nLoading : "+v.name+"</pre>");

	
	if(data) // we have loaded something
	{
		
		window.lua.preloadstring(L,data,v.name);

// console.log(v.name + " : " + v.file);

		preload_lua_idx++;
	}

	v=preload_lua_list[preload_lua_idx]; // idx may have changed
	
// trigger the next load
	if(v)
	{
		$.ajax({
			url : v.file,
			success : preload_lua_func
		});
	}
	else // done it all
	{
		preload_lua_done();
	}
}




// final call, all modules have been preloaded from server we can now start
var preload_lua_done=function(){

	var r=window.lua.dostring(L,'\
\
	yarn=require("yarn")\
	yarn.setup()\
	yarn.update()\
	return yarn.draw()\
\
',"yarn");

	$("#displayhack").html("<pre class='prehack'>"+r+"</pre>"); //initial display

	function getkey(code){
		if (code == '37') { return "left"; }
		if (code == '38') { return "up"; }
		if (code == '39') { return "right"; }
		if (code == '40') { return "down"; }
		if (code == '32') { return "space"; }
		return("");
	}
	
	$(document).keydown(function(event){
		var key=getkey(event.keyCode);
		if (key) { var r=window.lua.dostring(L,'yarn.keypress("","'+key+'","down")',"keydown"); }
	});
	
	$(document).keyup(function(event){
		var key=getkey(event.keyCode);
		if (key) { var r=window.lua.dostring(L,'yarn.keypress("","'+key+'","up")',"keyup"); }
	});

	setInterval(function(){	
		var r=window.lua.dostring(L,'\
	local r=yarn.update()\
	if r>0 then \
		return yarn.draw()\
	else\
		return nil\
	end \
',"hack");
		if(r) { $("#displayhack").html("<pre class='prehack'>"+r+"</pre>"); }
	},100); //10fps
};


if(window.lua) // the java stuff is ready?
{
	L=window.lua.create();		
	preload_lua_func();
}
else // set a callback to run when it is loaded
{
	window.lua_onload=function() {
		L=window.lua.create();		
		preload_lua_func();
	};
}
