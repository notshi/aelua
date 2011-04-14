
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
local macro_replace=wet_string.macro_replace

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")

-- require all the module sub parts
local html=require("shoop.html")
local wakapages=require("waka.pages")
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
local opts_mods_shoop=(opts and opts.mods and opts.mods.shoop) or {}

module("shoop")

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
local sess,user=d_sess.get_viewer_session(srv)
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
	
	local tab={
		url=baseurl,
		posts=posts,
		get=get,
		put=put,
		sess=sess,
		user=user,
		toponly=true,
		image="force",
		post_text="Upload a new shoop!",
	}
	
-- pull in layout data from the wiki page shoop
	local refined=wakapages.load(srv,"/shoop")[0] or {}

	refined.error=comments.post(srv,tab) or ""

-- the meta will contain the cache of everything, we may already have it due to updates	
	if not tab.meta then
		tab.meta=comments.manifest(srv,tab.url)
	end
	local cs=tab.meta.cache.comments or {}

	refined.thumbs={}

	local count=0
	for i,c in ipairs(cs) do
		refined.thumbs[i]=c		
		if i>=9 then break end
	end
	if refined.thumbs[1] then
		refined.thumbs.plate="plate_thumb"
	else
		refined.thumbs="{nothumbs}"
	end
	refined.plate_thumb=refined.plate_thumb or [[<a href="/data/{it.media}"><img style="width:200px;height:150px;" src="/thumbcache/crop/200/150/data/{it.media}"/></a>]]
	refined.postform=comments.get_reply_form(srv,tab,0)
	refined.plate_shoop=refined.plate_shoop or "{error}{thumbs}{postform}"

	refined.title=refined.title or "shoops"


	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title=refined.title})
	put( macro_replace(refined.plate_shoop, refined ) )
	put("footer")
	
end

