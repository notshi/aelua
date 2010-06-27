
local dat=require("wetgenes.aelua.data")

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-----------------------------------------------------------------------------
--
-- an error response
--
-----------------------------------------------------------------------------
function serv_fail(srv)

	srv.set_mimetype("text/html")
	srv.put([[
	
PAGE MISSING<br/>
<br/>
<a href="/">return to the homepage?</a><br/>

]])

end


-----------------------------------------------------------------------------
--
-- a very simple map for content to serv
--
-- these take the first part of the url before any /
-- this has no suport for query strings so dont use them :)
--
-----------------------------------------------------------------------------
serv_apps={ -- base lookup table 

["#default"]	=	serv_fail, -- bad link if we do not understand

[""]			=	"serv_home", -- home for /
["home"]		=	"serv_home", -- home for home

["test"]		=	"serv_test", -- test junk

["chan"]		=	{			-- a module
						["#default"]	=	"chan", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"chan", 		-- use this flavour when serving
						["image"]		=	"chan.image",	-- trimmed down image server code
						["thumb"]		=	"chan.image",
					},

["dice"]		=	{			-- a module
						["#default"]	=	"dice", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"dice", 		-- use this flavour when serving
					},
					
["console"]		=	{			-- a module
						["#default"]	=	"console", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"console", 		-- use this flavour when serving
					},
}



-----------------------------------------------------------------------------
--
-- the main serv function, named the same as the file it is in
--
-----------------------------------------------------------------------------
function serv(srv)

	srv.clock=os.clock() -- a relative time we started at
	srv.time=os.time() -- the absolute time we started

	srv.url_slash=str_split("/",srv.url) -- break the input url	
	
	local lookup=serv_apps
	local cmd
	local f
	local flavour
	
	srv.url_slash_idx=4 -- let the caller know which part of the path called them
	srv.flavour=nil -- sub modules can use this flavour to seperate themselves depending when called
	
	local loop=true
	
	while loop do
	
		loop=false -- end loop unless we change our mind later
		
		local slash=srv.url_slash[ srv.url_slash_idx ]
		
		if slash then
		
			cmd=lookup[ slash ] -- lookup the cmd from its flavour
			
			if not cmd then -- missing slash
							
				cmd=lookup[ "#default" ] -- get default from current rule
				
			end
			
		else
		
			cmd=lookup[ "#default" ] -- no slash so get default from current rule
		
		end
		
		if type(cmd)=="table" then -- a table with sub rules
		
			loop=true -- run this loop again with a new lookup table
			
			lookup=cmd -- use this sub table for new lookup
			
			srv.url_slash_idx=srv.url_slash_idx+1 -- move the slash index along one
			srv.flavour=lookup[ "#flavour" ] -- get flavour of this table
		
		elseif type(cmd)=="string" then -- a string so require that module and use its serv func
		
			local m=require(cmd) -- get module, this may load many other modules files at this point
			
			f=m.serv -- get function to call
			
		end
			
	end
	
	
	if not f then f=serv_fail end -- default
	
	f(srv) -- handle this base url
	
end


