
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
local pairs=pairs
local type=type

module("opts")

mail={}
mail.from="spam@hoe-house.appspotmail.com"

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
						["#opts"]		=	{
												url="/hoe",
											},
					},
					
["admin"]		=	{			-- all admin stuff
						["#default"]	=	"admin",
						["#opts"]		=	{
												url="/admin",
											},
						["console"]		=	{			-- a console module
											["#default"]	=	"console",
											["#flavour"]	=	"hoe",
											["#opts"]		=	{
																	url="/admin/console",
																},
											},
					},
					
["dumid"]		=	{			-- a dumid module
						["#default"]	=	"dumid", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
						["#opts"]		=	{
												url="/dumid",
											},
					},

["thumbcache"]		=	{			-- cache some images
						["#default"]	=	"thumbcache", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/thumbcache",
											},
					},
					
["help"]		=	{			-- a wiki like module
						["#default"]	=	"waka", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
						["#opts"]		=	{
												url="/help",
											},
					},
					
["blog"]		=	{			-- a blog module
						["#default"]	=	"blog", 		-- no badlinks, we own everything under here
						["#flavour"]	=	"hoe", 			-- use this flavour when serving
						["#opts"]		=	{
												url="/blog",
											},
					},
					
["note"]		=	{			-- a sitewide comment module
						["#default"]	=	"note", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/note",
											},
					},

["profile"]		=	{			-- a sitewide comment module
						["#default"]	=	"profile", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/profile",
											},
					},

["data"]		=	{			-- a data module
						["#default"]	=	"data", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/data",
											},
					},

}


mods={}

for i,v in pairs(map) do
	if type(v)=="table" then
		local name=v["#default"]
		if name then
			local t=mods[name] or {}
			mods[name]=t
			for i,v in pairs( v["#opts"] or {} ) do
				t[i]=v -- copy opts into default for each mod
			end
		end
	end
end

mods.init={}

mods.console=mods.console or {}
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
