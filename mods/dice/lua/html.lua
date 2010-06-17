

local sys=require("wetgenes.aelua.sys")

local wet_html=require("wetgenes.html")

local html=require("html")

local setmetatable=setmetatable

module("dice.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 



-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
dice_test=function(d)

		
	return wet_html.replace([[
	
This is a test.

]],d)

end
			
			


