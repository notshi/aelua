
--local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

--local dat=require("wetgenes.aelua.data")

--local user=require("wetgenes.aelua.user")

local img=require("wetgenes.aelua.img")

local fetch=require("wetgenes.aelua.fetch")

local cache=require("wetgenes.aelua.cache")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

--local wet_string=require("wetgenes.string")
--local str_split=wet_string.str_split
--local serialize=wet_string.serialize


-- require all the module sub parts
--local html=require("thumbcache.html")



local math=math
local string=string
local table=table
local os=os

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type
local require=require

module("thumbcache")

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)

	local cachename="thumbcache&"..srv.url
	if srv.query and #srv.query>0 then
		cachename=cachename.."?"..srv.query
	end

	local data
	local image
	
	
	for i=1,100 do
	
		data=cache.get(srv,cachename)
		
		if type(data)=="string" and data=="*" then -- another thread is fetching the image we should wait for them
--			log("sleeping")
		
			sys.sleep(1)
		
		elseif data then -- we got an image
--			log("cache")
		
			srv.set_mimetype( data.mimetype )
			srv.set_header("Cache-Control","public") -- allow caching of page
			srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
			srv.put(data.data)
			return
			
		elseif not data then -- we will go get it
--			log("web")
		
			if cache.put(srv,cachename,"*",10,"ADD_ONLY_IF_NOT_PRESENT") then -- get a 10sec lock

				local s1=srv.url_slash[ srv.url_slash_idx ]
				
				local lastarg=1
				local mode="fit" -- fit into a size, may produce an image of different aspect
				local hx=100
				local hy=100
				
				if s1=="crop" then 
				
					mode="crop" -- we force crop to keep aspect ratio
					hx=tonumber( srv.url_slash[ srv.url_slash_idx+1 ] or 100) or 100
					hy=tonumber( srv.url_slash[ srv.url_slash_idx+2 ] or 100) or 100
					lastarg=2
					
				else
				
					hx=tonumber( srv.url_slash[ srv.url_slash_idx+0 ] or 100) or 100
					hy=tonumber( srv.url_slash[ srv.url_slash_idx+1 ] or 100) or 100
					lastarg=1
				end
			
				local t={}
				for i=1,#srv.url_slash do local v=srv.url_slash[i]
					if i>srv.url_slash_idx+lastarg then
						t[#t+1]=v
					end
				end
				
				if t[1]=="data" then -- grab local data
					data=require("data").read(srv,t[2]) -- grab our data
					if data then data=data.data end -- check
				else -- grab from internets
				
					local url="http://"..table.concat(t,"/") -- build the remote request string
					if srv.query and #srv.query>0 then
						url=url.."?"..srv.query
					end
					data=fetch.get(url) -- get from internets
					if data then data=data.body end -- check
				end
				
				if data then
				
					local width=hx or 100
					local height=hy or 100

					if width<1 then width=1 end
					if width>1024 then width=1024 end

					if height<1 then height=1 end
					if height>1024 then height=1024 end

					image=img.get(data) -- convert to image
					

-- crop it to desired aspect ratio and or size?
				local px=0
				local py=0
				local ix=image.width
				local iy=image.height
					
				if mode=="crop" then
					local sx=width
					local sy=height
					if (ix/iy) > (sx/sy) then -- widthcrop
						ix=math.floor(iy*(sx/sy))
						px=0-math.floor((image.width-ix)/2)
					elseif (iy/ix) > (sy/sx) then -- heightcrop
						iy=math.floor(ix*(sy/sx))
						py=0-math.floor((image.height-iy)/2)
					end					
				else
				end

--log(ix.." , "..iy.." : "..px.." , "..py)

				image=img.composite({
					format="DEFAULT",
					width=ix,
					height=iy,
					color=16777215, -- white, does not work?
					{image,px,py,1,"TOP_LEFT"},
				}) -- and force it to a JPEG with a white? background

				image=img.resize(image,width,height,"JPEG") -- resize image and force to jpeg

					
					cache.put(srv,cachename,{
						data=image.data ,
						size=image.size ,
						width=image.width ,
						height=image.height ,
						format=image.format ,
						mimetype="image/"..string.lower(image.format),
						},60*60)
				
					srv.set_mimetype( "image/"..string.lower(image.format) )
					srv.set_header("Cache-Control","public") -- allow caching of page
					srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
					srv.put(image.data)
				
					return
				end
			end
		end
	end
	
end


