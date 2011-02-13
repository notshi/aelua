
local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")

-- require all the module sub parts
local html=require("chan.html")
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
local opts_mods_chan=(opts and opts.mods and opts.mods.chan) or {}

module("forum")

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
local sess,user=d_Sess.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)
local forums=srv.opts.forums

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
	
	local forum_name=srv.url_slash[srv.url_slash_idx+0]
	if forum_name and forums[forum_name] then
		baseurl=baseurl.."/"..forum_name
	
		local num=math.floor( tonumber( srv.url_slash[srv.url_slash_idx+1] or 0 ) or 0 )
		
		if num~=0 and tostring(num)==srv.url_slash[srv.url_slash_idx+1] then --got us an id
		
			local ent=comments.get(srv,num)
			
			
			if ent then -- got a comment page? only if its url matches our base
			
				if ent.cache.url == baseurl then
					srv.set_mimetype("text/html; charset=UTF-8")
					put("header",{title="forum ",H={user=user,sess=sess}})


					local tab={url=baseurl.."/"..num,posts=posts,get=get,put=put,sess=sess,user=user}
					
					
					put( comments.build_get_comment(srv,tab,ent.cache) )

					put( [[<div><a href="{url}">return to posts</a></div>]],{url=baseurl} )
					
					comments.build(srv,tab)
					
					if tab.modified then -- need to rebuild cache

	-- build pagecomments meta cache			

						local cs=comments.list(srv,{limit=5,sortdate="DESC",url=tab.url})
						local pagecomments={}
						for i,v in ipairs(cs) do -- and build comment cache
							pagecomments[i]=v.cache
						end
						
	--log("count : "..(#pagecomments))

	-- the comment cache may lose one if multiple people reply at the same time

						local meta=comments.update(srv,num,function(srv,e)
						
							e.cache.pagecomments=pagecomments -- save new comment cache
							e.cache.pagecount=tab.ret.count -- a number to sort by?
							
							return true
						end)
						
						comments.update_meta_cache(srv,baseurl)
						
					end

					
					put("footer")
		
					return
				end
			end
			
		end

		srv.set_mimetype("text/html; charset=UTF-8")
		put("header",{title="forum ",H={user=user,sess=sess}})

		comments.build(srv,{url=baseurl,posts=posts,get=get,put=put,sess=sess,user=user,toponly=true})
		
		put("footer")
		return
	end
	
-- list all available forums

	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="forum ",H={user=user,sess=sess}})

	for i,v in ipairs(forums) do
		put([[<a href="/forum/{name}">{name}</a><br/>]],{name=v.id})
	end
	
	put("footer")
	
end

