
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")
local user=users.get_viewer()

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html=require("chan.html")
local chan_data=require("chan.data")



local math=math
local string=string

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber

module("chan")

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)

local function put(a,b)
	b=b or {}
	b.srv=srv
	srv.put(wet_html.get(html,a,b))
end

	if post(srv) then return end -- post handled everything

	srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	
	put("chan_form",{})

--	srv.put("<br/><br/>"..tostring(srv.posts).."<br/><br/>")
--	srv.put("<br/><br/>"..tostring(srv.uploads).."<br/><br/>")
	
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

	if not user then -- must be logged in?
	
		log("user must be logged in to post, this should cause an error")

		return false	
	end
	
	local tab={}
	
	if srv.posts.subject and srv.posts.message then
	
		tab.subject=srv.posts.subject
		tab.body=srv.posts.message
		tab.email=user.cache.email
		tab.ip=srv.ip
		tab.image=0
		
		if srv.uploads.file and srv.uploads.file.size>0 then -- got a file
		
			local image=img.get(srv.uploads.file.data)
			local thumb=img.resize(image,200,200)
			local image_id=chan_data.create_image({image=image,thumb=thumb})
			
			tab.image=image_id
			
		end
		
		chan_data.create_thread(tab)

		srv.redirect("/chan")
		return true
	end

end

