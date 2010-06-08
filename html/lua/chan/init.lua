

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


local ipairs=ipairs

local math=math
local tostring=tostring

module("chan")

-----------------------------------------------------------------------------
--
-- the serv function, named the same as the file it is in
--
-----------------------------------------------------------------------------
function serv(srv)

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
	
		return false	
	end
	
	if srv.posts.subject and srv.posts.message then
	
		local image=img.get_img(srv.uploads.file.data)
		
log(tostring(image))
	
		local tab={}
		
		tab.subject=srv.posts.subject
		tab.body=srv.posts.message
		tab.email=user.user.email
		tab.ip=srv.ip
		tab.image=""
		
		chan_data.create_thread(tab)

--		srv.redirect("/chan")
--		return true
	end

end


