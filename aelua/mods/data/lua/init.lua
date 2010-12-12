
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local replace=wet_string.replace
local macro_replace=wet_string.macro_replace
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")

-- require all the module sub parts
local html=require("data.html")
local meta=require("data.meta")
local file=require("data.file")

local comments=require("note.comments")


local math=math
local string=string
local table=table
local os=os

local ipairs=ipairs
local pairs=pairs
local tostring=tostring
local tonumber=tonumber
local type=type
local pcall=pcall
local loadstring=loadstring

-- our options
local opts_mods_blog={} or ( opts and opts.mods and opts.mods.blog )


local LAYER_PUBLISHED = 0
local LAYER_DRAFT     = 1
local LAYER_SHADOW    = 2

module("data")

-----------------------------------------------------------------------------
--
-- create get and put wrapper functions
--
-----------------------------------------------------------------------------
local function make_get_put(srv)
	local get=function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
	local put=function(a,b)
		srv.put(get(a,b))
	end
	return get,put
end


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
	if srv.url_slash[srv.url_slash_idx+0]=="" and srv.url_slash[srv.url_slash_idx+1]=="admin" then
--		return serv_admin(srv)
	end
	
local sess,user=users.get_viewer_session(srv)
local get,put=make_get_put(srv)

	local num=math.floor( tonumber( srv.url_slash[srv.url_slash_idx+0] or 0 ) or 0 )
	
	if num~=0 and tostring(num)==srv.url_slash[srv.url_slash_idx+0] then --got us an id
	
		local em=meta.get(srv,num)
		
		if em then -- got a data file to serv
		
			local ef=file.get(srv,em.cache.filekey)
			
			if ef then
			
				srv.set_mimetype(em.cache.mimetype)
				srv.put(ef.cache.data)
				
				return			
			end
		
		end
		
	end
	
	
	
-- upload / list for admin

	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="data : "})
	local H={sess=sess,user=user}
	put("home_bar",{H=H})
	put("user_bar",{H=H})
	
--	put(tostring(user and user.cache),{H=H})
	if user and user.cache and user.cache.admin then -- admin
	
		local posts={} -- remove any gunk from the posts input
		if srv.method=="POST" and srv.headers.Referer and srv.headers.Referer==srv.url then
			for i,v in pairs(srv.posts) do
				posts[i]=v
			end
		end
		
		posts["filedata"]=srv.uploads["filedata"] -- uploaded file
				
		for i,v in pairs({"filename","mimetype","submit"}) do
			if posts[v] then posts[v]=trim(posts[v]) end
		end
		for i,v in pairs({"dataid"}) do
			if posts[v] then posts[v]=tonumber(posts[v]) end
		end
	
--		put(tostring(posts).."<br/>",{H=H})
		
		local pubname
		
		if posts.submit=="Upload" then
			if posts.dataid==0 then -- a new file
				if posts.filedata then -- got a file to create
		
					local em=meta.create(srv)
					local ef=file.create(srv)
					local emc=em.cache
					local efc=ef.cache
					
					efc.data=posts.filedata.data
					efc.size=posts.filedata.size
					emc.size=posts.filedata.size
					emc.owner=user.cache.email
					if posts.mimetype and posts.mimetype=="" then
					
						local l3=posts.filedata.name:sub(-3):lower()
						local l4=posts.filedata.name:sub(-4):lower()
						
						if l3=="jpg" or l4=="jpeg" then
						
							emc.mimetype="image/jpeg"
							
						elseif l3=="png" then
						
							emc.mimetype="image/png"
							
						elseif l3=="gif" then
						
							emc.mimetype="image/gif"
							
						elseif l3=="txt" then
						
							emc.mimetype="text/plain"
							
						elseif l3=="css" then
						
							emc.mimetype="text/css"
							
						elseif l3=="htm" or l4=="html" then
						
							emc.mimetype="text/html"
							
						else
						
							emc.mimetype="application/octet-stream"
							
						end
						
					else
						emc.mimetype=posts.mimetype
					end
									
					meta.put(srv,em)  -- write once to get an id for the meta
					emc=em.cache
					
					efc.metakey=emc.id -- the new id					
					file.put(srv,ef) -- save the data
					efc=ef.cache
					
					emc.filekey=efc.id -- the new id
					if posts.filename and posts.filename=="" then
						emc.pubname="/"..emc.id .."/".. posts.filedata.name -- default url
					else
						emc.pubname=posts.filename
					end
					meta.put(srv,em)  -- save the meta
					emc=em.cache
					
					pubname=emc.pubname
				end
			end
		end
		
--		put("<img src=\"/data{pubname}\" />",{H=H,pubname=pubname})
			
		put("data_upload_form",{H=H})
		
		local t=meta.list(srv,{sort="usedate"})
		
		for i,v in ipairs(t) do
		
			put("data_list_item",{H=H,it=v})
		
		end
		
	end
	
	put("footer")
	
end

