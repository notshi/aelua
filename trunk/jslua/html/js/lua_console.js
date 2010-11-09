
var L; // this will be our lua state

// lua has no fileaccess for module loading
// so instead all modulefiles must be preloaded and shoved into package.preload
// a little bit harsh for requesting lots of small files
// but it will do for now

var preload_lua_list=[
/*
	{file:"/luac/hack.lua",name:"hack"},
	{file:"/luac/hack/attr.lua",name:"hack.attr"},
	{file:"/luac/hack/cell.lua",name:"hack.cell"},
	{file:"/luac/hack/chardata.lua",name:"hack.chardata"},
	{file:"/luac/hack/charfight.lua",name:"hack.charfight"},
	{file:"/luac/hack/char.lua",name:"hack.char"},
	{file:"/luac/hack/itemdata.lua",name:"hack.itemdata"},
	{file:"/luac/hack/item.lua",name:"hack.item"},
	{file:"/luac/hack/level.lua",name:"hack.level"},
	{file:"/luac/hack/map.lua",name:"hack.map"},
	{file:"/luac/hack/menu.lua",name:"hack.menu"},
	{file:"/luac/hack/room.lua",name:"hack.room"}
*/
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




// final call, all modules have been preloaded from server
var preload_lua_done=function(){


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
