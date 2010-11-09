
var L; // this will be our lua state

// lua has no fileaccess for module loading
// so instead all modulefiles must be preloaded and shoved into package.preload
// a little bit harsh for requesting lots of small files
// but it will do for now

var preload_lua_list=[

	{file:"/jslua/yarn.lua",			name:"yarn"},
	{file:"/jslua/yarn/attr.lua",		name:"yarn.attr"},
	{file:"/jslua/yarn/cell.lua",		name:"yarn.cell"},
	{file:"/jslua/yarn/chardata.lua",	name:"yarn.chardata"},
	{file:"/jslua/yarn/charfight.lua",	name:"yarn.charfight"},
	{file:"/jslua/yarn/char.lua",		name:"yarn.char"},
	{file:"/jslua/yarn/itemdata.lua",	name:"yarn.itemdata"},
	{file:"/jslua/yarn/item.lua",		name:"yarn.item"},
	{file:"/jslua/yarn/level.lua",		name:"yarn.level"},
	{file:"/jslua/yarn/map.lua",		name:"yarn.map"},
	{file:"/jslua/yarn/menu.lua",		name:"yarn.menu"},
	{file:"/jslua/yarn/room.lua",		name:"yarn.room"}

];
var preload_lua_idx=0;
var preload_lua_func;

preload_lua_func=function(data){
	
	var v=preload_lua_list[preload_lua_idx];
	
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
