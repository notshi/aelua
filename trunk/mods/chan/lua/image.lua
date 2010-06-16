

-- image serv with trimmed down fat


local dat=require("wetgenes.aelua.data")


local math=math
local string=string

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber

module("chan.image")


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)

	if srv.url_slash[5] then
	
		if srv.url_slash[5]=="thumb" then
		
			return serv_image(srv,"thumb",srv.url_slash[6] or "0")
		
		elseif srv.url_slash[5]=="image" then
		
			return serv_image(srv,"image",srv.url_slash[6] or "0")
			
		end
	
	end

-- error


	
end


-----------------------------------------------------------------------------
--
-- serv up an image instead of a page
--
-----------------------------------------------------------------------------
function serv_image(srv,name,ids)

-- set kind depending on request

	local kind="chan.image"
	if name=="thumb" then kind="chan.thumb" end
	
-- get numerical id of image

	local s1,s2=string.find(ids, '.',1,true)
	local id=ids
	if s1 then id=string.sub(ids,1,s1-1) end
	id=tonumber(id) or 0
		
-- grab from datastore

	local ent={}
	ent.key={kind=kind,id=id}
	
	dat.get(ent)
	
-- and serv

	if ent.props then -- got an image
	
		srv.set_mimetype( "image/"..string.lower(ent.props.format) )
		
		srv.put(ent.props.data)
		
	else -- error
	
		srv.put(tostring(ent))
	
	end

end





