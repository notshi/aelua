

local wet_html=require("wetgenes.html")

local html=require("html")

local setmetatable=setmetatable

module("hoe.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 


-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)

	d=d or {}
	
	return html.footer(d)
end




