
local os=os
local ae_opts=require("wetgenes.aelua.opts")
local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local loadstring=loadstring
local setfenv=setfenv
local pcall=pcall

module("opts")

users={}
users.admin={ -- users with admin rights for this app
	["notshi@gmail.com"]=true,
	["14@id.wetgenes.com"]=true,
	["krissd@gmail.com"]=true,
	["2@id.wetgenes.com"]=true,
}

map={ -- base lookup table 

["#default"]	=	serv_fail, -- bad link if we do not understand
["#flavour"]	=	"hoe", 
["#index"]		=	"hoe", 
					
["hoe"]			=	{			-- the base module
						["#default"]	=	"hoe", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 		-- use this flavour when serving
					},
					
["admin"]		=	{			-- all admin stuff
	["#default"]	=	"admin",
	["console"]		=	{			-- a console module
						["#default"]	=	"console", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
					},
},
					
["dumid"]		=	{			-- a dumid module
						["#default"]	=	"dumid", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
					},
					
["help"]		=	{			-- a wiki like module
						["#default"]	=	"waka", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
					},
					
["blog"]		=	{			-- a blog module
						["#default"]	=	"blog", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
					},
--[[					
["note"]		=	{			-- a sitewide comment module
						["#default"]	=	"note", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
					},
]]
}


mods={}

mods.init={}

mods.console={}

mods.console.input=
[[
local srv=(...)
local hoe=require("hoe")
local con=require("hoe.con")
local H=hoe.create(srv)

print(con.help(H))
]]

lua = ae_opts.get_dat("lua")
if lua then
	local f=loadstring(lua)
	if f then
		setfenv(f,_M)
		pcall( f )
	end
end
