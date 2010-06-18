
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local dat=require("wetgenes.aelua.data")

local user=require("wetgenes.aelua.user")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html=require("dice.html")



local math=math
local string=string
local table=table

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type

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

	local slash=srv.url_slash[ srv.url_slash_idx ]
	if slash=="image" then return image(srv) end
		
local function put(a,b)
	b=b or {}
	b.srv=srv
	srv.put(wet_html.get(html,a,b))
end


	srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{})
	
	put("dice_test",{})
	
	local count=1
	local sides=6
		
	if slash and slash~="" then -- requested format, eg 2d6
	
		local ds=wet_string.str_split("d",slash)
		count=math.floor( tonumber(ds[1] or 1) or 1 )
		sides=math.floor( tonumber(ds[2] or 6) or 6 )
		
	end
	
	if count<1 then count=1 end
	if count>10 then count=10 end
	if sides<1 then sides=1 end
	if sides>20 then sides=20 end
	
	put("You have requested {count} dice with {sides} sides.<br/>",{count=count,sides=sides})
	
	local rolls={}
	for i=1,count do
		rolls[i]=math.random(1,sides)
	end
	
	local imgid=sides.."/"..table.concat(rolls,".")
	
	put("<a href=\"/dice/image/{imgid}.jpg\"><img src=\"/dice/image/{imgid}.jpg\"/></a><br/>",{count=count,sides=sides,imgid=imgid})
	
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

-----------------------------------------------------------------------------
--
-- return an image
--
-----------------------------------------------------------------------------
function image(srv)

	local base=tonumber(srv.url_slash[ srv.url_slash_idx+1 ] or 6) or 6
	local slash=srv.url_slash[ srv.url_slash_idx+2 ]

	local code=wet_string.str_split(".",slash)
	local nums={}
	for i=1,#code do
		local n=tonumber(code[i])
		if n then table.insert(nums,n) end
	end
	
	local imgs={}
	local comp={width=#nums*100, height=100, color=0, format="JPEG"}
	for i=1,#nums do local v=nums[i]
		if not imgs[v] then imgs[v]=img.get(sys.file_read("art/dice/d6."..v..".png")) end -- load image
		table.insert(comp,{imgs[v],100*(i-1),0,1,"TOP_LEFT"})
	end

	local t2=img.composite(comp)
	
	srv.set_mimetype( "image/"..string.lower(t2.format) )
	srv.put(t2.data)
		
end
