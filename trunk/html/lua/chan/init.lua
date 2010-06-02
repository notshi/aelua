

-- load up html template strings
dofile("lua/html.lua")
local html=require("wetgenes.html")


local sys=require("wetgenes.aelua.sys")

local dat=require("wetgenes.aelua.data")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
require("chan.html")


local math=math
local tostring=tostring

module("chan")

-----------------------------------------------------------------------------
--
-- the serv function, named the same as the file it is in
--
-----------------------------------------------------------------------------
function serv(srv)

local function put(a,b)
	srv.put(html.get(a,b))
end

	srv.set_mimetype("text/html")
	put("header",{})
	
	put("chan_form",{})

	srv.put("<br/><br/>"..tostring(srv).."<br/><br/>")

	put("footer",{time=math.ceil((sys.clock()-srv.clock_start)*1000)/1000})
	
end


