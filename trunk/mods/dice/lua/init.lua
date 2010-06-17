
local html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local dat=require("wetgenes.aelua.data")

local user=require("wetgenes.aelua.user")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local dice_html=require("dice.html")



local math=math
local string=string

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber

module("dice")

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)
	if post(srv) then return end -- post handled everything

local function put(a,b)
	b=b or {}
	b.srv=srv
	srv.put(html.get(dice_html,a,b))
end


	srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{})
	
	put("dice_test",{})

	put("footer",{})
	
end


-----------------------------------------------------------------------------
--
-- the post function, looks for post params and handles them
--
-----------------------------------------------------------------------------
function post(srv)

	return false

end

