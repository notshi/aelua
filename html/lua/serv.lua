
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
serv_apps={} -- base lookup table 

serv_apps[0]	=serv_fail -- bad link

serv_apps[""]		="serv_home" -- default
serv_apps["home"]	="serv_home" -- default

serv_apps["test"]	="serv_test"
serv_apps["chan"]	="chan"





-----------------------------------------------------------------------------
--
-- the main serv function, named the same as the file it is in
--
-----------------------------------------------------------------------------
function serv(srv)

	srv.clock_start=sys.clock() -- the time we started

	srv.url_slash=str_split("/",srv.url) -- break the input url	
	
	local f=serv_apps[ srv.url_slash[4] ]
	
	if type(f)=="string" then -- a string so load that file and run it
	
		if sys.file_exists("lua/"..f..".lua") then -- its a simple file
	
			dofile("lua/"..f..".lua")
			f=_G[f] -- expect it to contain a serv function of the same name as the file
			
		elseif sys.file_exists("lua/"..f.."/init.lua") then -- its a module
		
			f=require("chan")
			f=f.serv
			
		end
		
	end
	
	if not f then f=serv_fail end -- default
	
	f(srv) -- handle this base url
	
end


