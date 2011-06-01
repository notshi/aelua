
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
local macro_replace=wet_string.macro_replace

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")
local d_users=require("dumid.users")

-- require all the module sub parts
local html=require("profile.html")

local waka=require("waka")
local note=require("note")

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
local opts_mods_profile=(opts and opts.mods and opts.mods.profile) or {}

module("todo")

local function make_get_put(srv)
	local get=function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
	return  get , function(a,b) srv.put(get(a,b)) end
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)
	
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
	
	local name=srv.url_slash[srv.url_slash_idx+0] -- the task name, could be anything
	if name=="" then name=nil end -- can not be ""
	if name then name=name:lower() end -- force to lower
	
	if name then -- need to check the name is a valid thing
	
	end

-- by default list all possible things
	

end


-----------------------------------------------------------------------------
--
-- hook into waka page updates
--
-----------------------------------------------------------------------------
function waka_changed(srv,page)

	if not page then return end
	if tostring(page.key.id):sub(1,6)~="/todo/" then return end
	
	log(tostring(page.key.id))
	
	local chunks=wet_waka.text_to_chunks( page.cache.text )
	
	log(tostring(chunks.body.text))
end

-- add our hook to the waka stuffs, this should get called on module load
-- so that we always watch the waka edits, the trailing slash is to make sure that
-- we only catch task pages and bellow
waka.add_changed_hook("^/todo/",waka_changed)




-----------------------------------------------------------------------------
--
-- hook into note posts
--
-----------------------------------------------------------------------------
function note_posted(srv,page,parent)

	if not page then return end
	if tostring(page.key.id):sub(1,6)~="/todo/" then return end
	
	log("NOTE: "..tostring(page.key.id))
	
	local chunks=wet_waka.text_to_chunks( page.cache.text )
	
	log("NOTE: "..tostring(chunks.body.text))
end

-- add our hook to the waka stuffs, this should get called on module load
-- so that we always watch the waka edits, the trailing slash is to make sure that
-- we only catch task pages and bellow
note.add_posted_hook("^/todo/",note_posted)



