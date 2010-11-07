
var L; // this will be our lua state

// lua has no fileaccess for module loading
// so instead all modulefiles must be preloaded and shoved into package.preload
// a little bit harsh or requesting lots of small files
// but it will do for now

var preload_lua_list=[
	{file:"/lua/testmod.lua",name:"testmod"}
];
var preload_lua_idx=0;
var preload_lua_func;
var preload_lua_done=false;

preload_lua_func=function(data){
var v=preload_lua_list[preload_lua_idx];
	
	if(data) // we have loaded something
	{
		
window.lua_preloadstring(L,data,v.name);

console.log(v.name + " : " + v.file);

		preload_lua_idx++;
	}

	v=preload_lua_list[preload_lua_idx];
	
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
		preload_lua_done=true;
		runstuff();
	}
}





var runstuff=function(){

p=window.lua_dostring(L,'test=" test ".." to "..2 return "poop" ','maincode');
console.log(p);

//window.lua_set(L,'test','this is a test');

var t=window.lua_get(L,'test');

console.log(t);


//console.log("preload");
//window.lua_preloadstring(L,'local _G=_G ; module(...) _G.loadedtestmod="loaded test oh yes we have"','testmod');
//console.log("postload");

window.lua_dostring(L,'require("testmod")','precode');

var t=window.lua_get(L,'loadedtestmod');
console.log("got t");
console.log(t);


};

var runcheck;

runcheck=function() {
	if(window.lua_create) // wait for the java stuff to be ready
	{
console.log("loading");

		L=window.lua_create();
		
		preload_lua_func();
	}
	else
	{
console.log("waiting");
		window.setTimeout( runcheck , 1000); // try again later
	}
};


$(runcheck);
