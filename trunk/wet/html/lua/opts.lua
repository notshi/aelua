
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
local ipairs=ipairs
local type=type

module("opts")

bootstrapp_version=20110117 -- hand bump to todays date on release

urls={}

head={} -- stuff to inject into the html header
head.favicon="/favicon.ico" -- the favicon
head.extra_css={} -- more css links
head.extra_js={} -- more js links

users={}
users.admin={ -- users with hard and unremovable admin rights for this app
	["notshi@gmail.com"]=true,
	["krissd@gmail.com"]=true,
}

local app_name=nil -- best not to use an appname, unless we run multiple apps on one site 


forums={
	{
		id="spam",
		title="General off topic posts.",
	},
}
for i,v in ipairs(forums) do -- create id lookups as well
	forums[v.id]=v
end


map={ -- base lookup table 

["#index"]		=	"welcome", 
["#default"]	=	"waka", 		-- no badlinks, everything defaults to a wikipage
["#flavour"]	=	app_name, 			-- use this flavour when serving
["#opts"]		=	{
						url="/",
					},
										
["wiki"]		=	{			-- redirect
						["#redirect"]	=	"/", 		-- remap this url and below
					},
					
["blog"]		=	{			-- a blog module
						["#default"]	=	"blog", 		-- no badlinks, we own everything under here
						["#flavour"]	=	app_name, 			-- use this flavour when serving
						["#opts"]		=	{
												url="/blog",
												title="blog",
											},
					},


["admin"]		=	{			-- all admin stuff
						["#default"]	=	"admin",
						["console"]		=	{			-- a console module
											["#default"]	=	"console",
											["#flavour"]	=	app_name,
											["#opts"]		=	{
																	url="/admin/console/",
																},
											},
					},
					
["dumid"]		=	{			-- a dumid module
						["#default"]	=	"dumid", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/dumid",
											},
					},
					
					
["data"]		=	{			-- a data module
						["#default"]	=	"data", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/data",
											},
					},

["note"]		=	{			-- a sitewide comment module
						["#default"]	=	"note", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/note",
											},
					},

["chan"]		=	{			-- an imageboard module
						["#default"]	=	"chan", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/chan",
											},
					},

["forum"]		=	{			-- a forum module
						["#default"]	=	"forum", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/forum",
												forums=forums,
											},
					},

["profile"]		=	{			-- a profile module
						["#default"]	=	"profile", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/profile",
											},
					},

["dice"]		=	{			-- roll some dice
						["#default"]	=	"dice", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/dice",
											},
					},

["thumbcache"]		=	{			-- cache some images
						["#default"]	=	"thumbcache", 		-- no badlinks, we own everything under here
						["#opts"]		=	{
												url="/thumbcache",
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
print("test")
]]

lua = ae_opts.get_dat("lua")
if lua then
	local f=loadstring(lua)
	if f then
		setfenv(f,_M)
		pcall( f )
	end
end
