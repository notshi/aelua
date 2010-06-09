

-- load up html template strings
dofile("lua/html.lua")
local html=require("wetgenes.html")


local sys=require("wetgenes.aelua.sys")

local dat=require("wetgenes.aelua.data")

local user=require("wetgenes.aelua.user")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local chan_html=require("chan.html")
local chan_data=require("chan.data")



local math=math
local string=string

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber

module("chan")

-----------------------------------------------------------------------------
--
-- the serv function, named the same as the file it is in
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

local function put(a,b)
	b=b or {}
	b.srv=srv
	srv.put(html.get(a,b))
end

	if post(srv) then return end -- post handled everything

	srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{})
	
	put("chan_form",{})

	srv.put("<br/><br/>"..tostring(srv.posts).."<br/><br/>")
	srv.put("<br/><br/>"..tostring(srv.uploads).."<br/><br/>")
	
	local ts=chan_data.get_threads("new")
	
	for i,v in ipairs(ts) do

		put("chan_post",{post=v})
		
	end

	put("footer",{})
	
end


-----------------------------------------------------------------------------
--
-- the post function, looks for post params and handles them
--
-----------------------------------------------------------------------------
function post(srv)

	if not user.user then -- must be logged in?
	
		log("user must be logged in to post, this should cause an error")

		return false	
	end
	
	local tab={}
	
	if srv.posts.subject and srv.posts.message then
	
		tab.subject=srv.posts.subject
		tab.body=srv.posts.message
		tab.email=user.user.email
		tab.ip=srv.ip
		tab.image=0
		
		if srv.uploads.file then -- got a file
		
			local image=img.get(srv.uploads.file.data)
			local thumb=img.resize(image,200,200)
			local image_id=chan_data.create_image({image=image,thumb=thumb})
			
			tab.image=image_id
			
		end
		
		chan_data.create_thread(tab)

--		srv.redirect("/chan")
--		return true
	end

end


-----------------------------------------------------------------------------
--
-- serv up an image instead of a page, this is ineficient to do here and should be moved somewhere else :)
-- but for now we shall let it slide
--
-----------------------------------------------------------------------------
function serv_image(srv,name,ids)

	local kind="chan.image"
	if name=="thumb" then kind="chan.thumb" end
	
	local s1,s2=string.find(ids, '.',1,true)
	local id=ids
	if s1 then id=string.sub(ids,1,s1-1) end
	id=tonumber(id) or 0
		
	local ent={}
	ent.key={kind=kind,id=id}
	
	dat.get(ent)
	
log(tostring(ent))

	if ent.props then -- got an image
	
		srv.set_mimetype( "image/"..string.lower(ent.props.format) )
		
		srv.put(ent.props.data)
		
	else
	
		srv.put(tostring(ent))
	
	end

end





