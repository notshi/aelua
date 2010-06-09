
local sys=require("wetgenes.aelua.sys")
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

[0]			=	serv_fail, -- bad link

[""]		=	"serv_home", -- default
["home"]	=	"serv_home", -- default

["test"]	=	"serv_test", -- a test file

["chan"]	=	{			-- a module
					[0]			=	"chan",
					[""]		=	"chan",
					["image"]	=	"chan.image",	-- special trimmed down chan simage server
					["thumb"]	=	"chan.image",
				},

}



-----------------------------------------------------------------------------
--
-- the main serv function, named the same as the file it is in
--
-----------------------------------------------------------------------------
function serv(srv)

	srv.clock_start=sys.clock() -- the time we started

	srv.url_slash=str_split("/",srv.url) -- break the input url	
	
	local lookup=serv_apps
	local cmd
	local f
	
	srv.url_slash_idx=4 -- let the caller know which part of the path called them
	srv.url_slash_name=nil -- sub modules can use this name to seperate themselves depending on their url, eg multiple chan boards
	
	local loop=true
	
	while loop do
	
		loop=false -- end loop unless we change our mind later
		
		srv.url_slash_name=srv.url_slash[ srv.url_slash_idx ]
		
		if srv.url_slash_name then
		
			cmd=lookup[ srv.url_slash_name ] -- lookup the cmd from its name
			
			if not cmd then -- missing command
				cmd=lookup[ 0 ] -- so get default from current rule
			end
		else
		
			cmd=lookup[ 0 ] -- no name so get default from current rule
		
		end
	
		
		if type(cmd)=="table" then -- a table with sub rules
		
			loop=true -- run this loop again with a new lookup table
			
			lookup=cmd -- use this sub table for new lookup
			
			srv.url_slash_idx=srv.url_slash_idx+1 -- move the slash index along one
		
		elseif type(cmd)=="string" then -- a string so require that module and use its serv func
		
			local m=require(cmd) -- get module, this may load many other modules files at this point
			
			f=m.serv -- get function to call
			
		end
			
	end
	
	
	if not f then f=serv_fail end -- default
	
	f(srv) -- handle this base url
	
end


