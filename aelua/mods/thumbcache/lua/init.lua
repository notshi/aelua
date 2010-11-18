
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

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type

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
	
		data=cache.get(cachename)
		
		if data=="*" then -- another thread is fetching the image we should wait for them
--			log("sleeping")
		
			sys.sleep(1)
		
		elseif data then -- we got an image
--			log("cache")
		
			srv.set_mimetype( "image/jpeg" )
			srv.put(data)
			return
			
		elseif not data then -- we will go get it
--			log("web")
		
			if cache.put(cachename,"*",60,"ADD_ONLY_IF_NOT_PRESENT") then -- get a 60sec lock

				local s1=srv.url_slash[ srv.url_slash_idx ]
				local s2=srv.url_slash[ srv.url_slash_idx+1 ]
			
				local t={}
				for i=1,#srv.url_slash do local v=srv.url_slash[i]
					if i>srv.url_slash_idx+1 then
						t[#t+1]=v
					end
				end
				local url="http://"..table.concat(t,"/") -- build the remote request string
				if srv.query and #srv.query>0 then
					url=url.."?"..srv.query
				end
				data=fetch.get(url).body -- get from internets
			
				local width=tonumber(s1 or "") or 100
				local height=tonumber(s2 or "") or 100

				if width<1 then width=1 end
				if width>1024 then width=1024 end

				if height<1 then height=1 end
				if height>1024 then height=1024 end

				image=img.get(data) -- convert to image

				image=img.resize(image,width,height) -- resize image
--[[
				image=img.composite({
					format="JPEG",
					width=width,
					height=height,
					color=0xffffff,
					{image,0,0,1,"TOP_LEFT"},
				}) -- and force it to a JPEG with a white background
]]
				image=img.resize(image,width,height,"JPEG") -- resize image and force it to a JPEG
			
				cache.put(cachename,image.data,60*60)
			
				srv.set_mimetype( "image/"..string.lower(image.format) )
				srv.put(image.data)
			
				return
			end
		end
	end
	
end


