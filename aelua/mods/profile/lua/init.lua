
local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")

-- require all the module sub parts
local html=require("profile.html")

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


-- opts
local opts_mods_profile=(opts and opts.mods and opts.mods.profile) or {}

module("profile")

local function make_put(srv)
	return function(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end
end
local function make_get(srv)
	return function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
end


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=users.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)
	
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /

-- this is the base url we use for comments
	local t={""}
	for i=4,srv.url_slash_idx-1 do
		t[#t+1]=srv.url_slash[i]
	end
	local baseurl=table.concat(t,"/")

-- handle posts cleanup
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv.headers.Referer and string.sub(srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	for n,v in pairs(srv.uploads) do
		posts[n]=v
	end
	
	local name=srv.url_slash[srv.url_slash_idx+0] -- the profile name, could be anything
	if name=="" then name=nil end -- can not be ""
	if name then name=name:lower() end -- force to lower
	
	if name then -- need to check the name is valid
		local pusr=users.get_user(name) -- get user from email or nickname
		if pusr then -- gots a user to display profile of
			baseurl=baseurl.."/"..name
			
			local content={}
			local list={ -- default stuff to display
					{
						form="name",
						display="head",
					},
				}
			content.list=list
			content.user=pusr.cache
			
			for i,v in ipairs(list) do -- get all chunks
				makechunk(content,v)
			end

			srv.set_mimetype("text/html; charset=UTF-8")
			put("header",{title="profile ",H={user=user,sess=sess}})

			put("profile_layout",content)

			comments.build(srv,{url=baseurl,posts=posts,get=get,put=put,sess=sess,user=user,post="admin",admin="me"})
			
			put("footer")
			
			return
		end
		
	end

-- nothing to see here, move along	
--	sys.redirect(srv,"/")
end




-----------------------------------------------------------------------------
--
-- build this chunk and put it into the content
--
-----------------------------------------------------------------------------
function makechunk(content,chunk)

	content.chunk=chunk
	local form=chunk.form
	
	local f=_M[ "makechunk_"..form ]
	if f then
		local r=f(content,chunk)
		local t=content[ chunk.display ] or {}
		t[#t+1]=r
		content[ chunk.display ]=t
	end
end


-----------------------------------------------------------------------------
--
-- the name of the person
--
-----------------------------------------------------------------------------
function makechunk_name(content,chunk)
	local user=content.user
	local d={}
	d.content=content
	d.chunk=chunk
	d.name=user.name
	local p=[[
<div class="profile_name">
Hello my name is <b>{name}</b>.
</div>
]]
	return replace(p,d)
end
