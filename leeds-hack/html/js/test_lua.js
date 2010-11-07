
var L; // this will be our lua state

// lua has no fileaccess for module loading
// so instead all modulefiles must be preloaded and shoved into package.preload
// a little bit harsh or requesting lots of small files
// but it will do for now

var preload_lua_list=[
//	{file:"/lua/testmod.lua",name:"testmod"}
];
var preload_lua_idx=0;
var preload_lua_func;
var preload_lua_done=false;

preload_lua_func=function(data){
var v=preload_lua_list[preload_lua_idx];
	
	if(data) // we have loaded something
	{
		
window.lua_preloadstring(L,data,v.name);

//console.log(v.name + " : " + v.file);

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


};

var runcheck;

runcheck=function() {
	if(window.lua_create) // wait for the java stuff to be ready
	{
//console.log("loading");

		L=window.lua_create();
		
		preload_lua_func();
	}
	else
	{
//console.log("waiting");
		window.setTimeout( runcheck , 1000); // try again later
	}
};


$(runcheck);
