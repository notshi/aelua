

local sys=require("wetgenes.aelua.sys")

local f=require("wetgenes.html")

local html_base=require("html_base")

local setmetatable=setmetatable

module("dice.html")

setmetatable(_M,{__index=html_base}) -- use a meta table to also return html_base 



-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
dice_test=function(d)

		
	return f.replace([[
	
This is a test.

]],d)

end
			
			


