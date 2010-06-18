
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

--local dat=require("wetgenes.aelua.data")

--local user=require("wetgenes.aelua.user")

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
--	put("user_bar",{})
	
	
	local style="plain"
	local count=2
	local side=6
	

	if slash and slash~="" then -- requested format, eg 2d6
	
		local ds=wet_string.str_split("d",slash)
		count=math.floor( tonumber(ds[1] or count) or count )
		side=math.floor( tonumber(ds[2] or side) or side )
		
	end

--	put(srv)
	
-- override with posts	
	local function varover(v)
		if not v then return end
		if v.count then
			count=math.floor( tonumber( v.count ) or count )
		end
		if v.side then
			side=math.floor( tonumber( v.side ) or side )
		end
	end	
	varover(srv.gets)
	varover(srv.posts)
	
	if count<1 then count=1 end
	if count>10 then count=10 end
	if side<1 then side=1 end
	if side>20 then side=20 end
	
	local styles={"plain"}
	local counts={1,2,3,4,5,6,7,8,9,10}
	local sides={4,6,8,12,20}
	put("dice_form",{counts=counts,sides=sides,styles=styles,count=count,side=side,style=style})
	
	local dienames={
					[4]="rough tetrahedrons",
					[6]="rough cubes",
					[8]="rough octahedrons",
					[12]="rough dodecahedrons",
					[20]="rough icosahedrons",
					}
	local diename=dienames[side] or side.." sided dice"
	put(
	[[
		<br/>
		The webmaster grabs a handful of {diename} and throws them high into the air.<br/>
		{count} of them land{ss} at your feet and stare{ss} up at you with the result.<br/>
		<br/>
	]],{count=count,side=side,diename=diename,ss=(count==1)and"s"or"" })
	
	local rolls={}
	for i=1,count do
		rolls[i]=math.random(1,side)
	end
	
	local imgid=side.."/"..table.concat(rolls,".")
	
	local width=count*100
	if width>960 then width=960 end
	
	put("<a href=\"/dice/image/plain/{imgid}.jpg\"><img src=\"/dice/image/plain/{imgid}.jpg\" width=\"{width}\"/></a><br/>",{count=count,sides=sides,imgid=imgid,width=width})
	
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

	local flavour=srv.url_slash[ srv.url_slash_idx+1 ]
	local base=tonumber(srv.url_slash[ srv.url_slash_idx+2 ] or 6) or 6
	local slash=srv.url_slash[ srv.url_slash_idx+3 ]

	local code=wet_string.str_split(".",slash)
	local nums={}
	for i=1,#code do
		local n=tonumber(code[i])
		if n then table.insert(nums,n) end
		if #nums==10 then break end
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
