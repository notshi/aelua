
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

--local dat=require("wetgenes.aelua.data")

--local user=require("wetgenes.aelua.user")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize
local macro_replace=wet_string.macro_replace


-- require all the module sub parts
local html=require("dice.html")



local math=math
local string=string
local table=table

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type

local require=require

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
	if slash=="image" then return image(srv) end -- image request
		
local function put(a,b)
	b=b or {}
	b.srv=srv
	srv.put(wet_html.get(html,a,b))
end
local function get(a,b)
	b=b or {}
	b.srv=srv
	return wet_html.get(html,a,b)
end


-- need the base wiki page, its kind of the main site everything
	local wakapages=require("waka.pages")
	local refined=wakapages.load(srv,"/dice")[0]	

	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="profile ",H={user=user,sess=sess}})

	refined.title="Dice"
	local body=""
	
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
	if count>16 then count=16 end
	if side<2 then side=2 end
	if side>20 then side=20 end
	
	local styles={"plain"}
	local counts={1,2,3,4,5,6,7,8,9,10,11,12,13,14}
	local sides={2,4,6,8,10,12,20}
	body=body..get("dice_form",{counts=counts,sides=sides,styles=styles,count=count,side=side,style=style})
	
	local dienames={
					[2]="eldritch coins",
					[4]="rough tetrahedrons",
					[6]="rough cubes",
					[8]="rough octahedrons",
					[12]="rough dodecahedrons",
					[20]="rough icosahedrons",
					}
	local diename=dienames[side] or side.." sided dice"
	body=body..get(
	[[
		<br/>
		The webmaster grabs a handful of {diename} and throws them high into the air.<br/>
		{count} land{ss} at your feet and stare{ss} up at you with the result.<br/>
		<br/>
	]],{count=count,side=side,diename=diename,ss=(count==1)and"s"or"" })
	
	local rolls={}
	for i=1,count do
		rolls[i]=math.random(1,side)
	end
	
	local imgid=side.."/"..table.concat(rolls,".")
	
	local width=count*100
	if width>960 then width=960 end
	
	body=body..get("<a href=\"/dice/image/plain/{imgid}.jpg\"><img src=\"/dice/image/plain/{imgid}.jpg\" width=\"{width}\"/></a><br/>",{count=count,sides=sides,imgid=imgid,width=width})
	
	refined.body=body;
	put( macro_replace(refined.plate or "{body}", refined ) )
			
	put("footer")

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
	
	local avail= -- the dice available for each flavour
	{
		plain={2,4,6,8,10,12,20},
	}
	
	if not avail[flavour] then flavour="plain" end -- check flavour, and default to plain
	local av=avail[flavour]

-- find the best die we have	
	local die=20
	for i=1,#av do local v=av[i]
		if v>=base then
			die=v
			break
		end
	end
					

	local code=wet_string.str_split(".",slash)
	local nums={}
	for i=1,#code do
		local n=tonumber(code[i])
		if n then table.insert(nums,n) end
		if #nums==16 then break end
	end
	
	local imgs={}
	local comp={width=#nums*100, height=100, color=tonumber("ffffff",16), format="JPEG"}
	for i=1,#nums do local v=nums[i]
		if not imgs[v] then imgs[v]=img.get(sys.file_read("art/dice/plain/d"..die.."."..v..".png")) end -- load image
		table.insert(comp,{imgs[v],100*(i-1),0,1,"TOP_LEFT"})
	end

	local t2=img.composite(comp)
	
	srv.set_mimetype( "image/"..string.lower(t2.format) )
	srv.put(t2.data)
		
end
