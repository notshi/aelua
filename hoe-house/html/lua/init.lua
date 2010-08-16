
require("opts") -- setup global opts table full of options and overides

local os=os
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

	srv.set_mimetype("text/html; charset=UTF-8")
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
-----------------------------------------------------------------------------
										
serv_apps={ -- base lookup table 

["#default"]	=	serv_fail, -- bad link if we do not understand
["#flavour"]	=	"hoe", 
["#index"]		=	"hoe", 
					
["hoe"]			=	{			-- the base module
						["#default"]	=	"hoe", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 		-- use this flavour when serving
					},
					
["admin"]		=	{			-- all admin stuff
	["#default"]	=	serv_fail, -- bad link if we do not understand
	["console"]		=	{			-- a console module
						["#default"]	=	"console", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
					},
},
					
["dumid"]		=	{			-- a dumid module
						["#default"]	=	"dumid", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
					},
					
["help"]		=	{			-- a wiki module
						["#default"]	=	"waka", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
					},
					
["note"]		=	{			-- a sitewide comment module
						["#default"]	=	"note", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
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
	srv.crumbs={} -- for crumbs based navigation 
	
	local lookup=serv_apps
	local cmd
	local f
	local flavour
	
	srv.url_slash_idx=4 -- let the caller know which part of the path called them
	srv.flavour=nil -- sub modules can use this flavour to seperate themselves depending when called
	
	srv.domain=srv.url_slash[3]
	if srv.domain then srv.domain=str_split(":",srv.domain)[1] end -- lose the port part
	
	srv.url_base=table.concat({srv.url_slash[1],srv.url_slash[2],srv.url_slash[3]},"/").."/"
	
	local loop=true
	
	while loop do
	
		loop=false -- end loop unless we change our mind later
		
		local slash=srv.url_slash[ srv.url_slash_idx ]
		
		if slash then
		
			if slash=="" then -- use a default index 
				slash=lookup[ "#index" ] or ""
			end
		
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
		
			srv.url_base=srv.url_base..slash.."/"
			srv.slash=slash -- the last slash table we looked up
			
		elseif type(cmd)=="string" then -- a string so require that module and use its serv func
		
			local m=require(cmd) -- get module, this may load many other modules files at this point
			
			f=m.serv -- get function to call
			
		end
			
	end
	
	if not f then f=serv_fail end -- default
	
	f(srv) -- handle this base url
	
end


