
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
local html=require("blog.html")
local pages=require("blog.pages")
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

-- our options
local opts_mods_blog={} or ( opts and opts.mods and opts.mods.blog )


local LAYER_PUBLISHED = 0
local LAYER_DRAFT     = 1
local LAYER_SHADOW    = 2

module("blog")

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
-- get a page group and name from part of a url
--
-- pass in url_slash , url_slash_idx
--
-- returns group , name
--
-- which can them be used to look up the appropriate page
--
-- "" is used as the name of a page when we wish to create a new one and have no name yet
--
-----------------------------------------------------------------------------
function get_page_name(aa,idx)
local group="/"
local name=""

	name=aa[#aa]
	for i=idx,#aa-1 do
		group=group..aa[i].."/"
	end
	
	return group,name
end


-----------------------------------------------------------------------------
--
-- get this entities parents and merge the chunks
--
-- return the merged and refined chunks
--
-----------------------------------------------------------------------------
function bubble(srv,ent,overload)
	local chunks={}	-- merge all pages and their parents into this
	local ps={}
	
	local function check(p)
	
		if #ps>=16 then return nil end -- max depth
		
		local s=p.cache.group
		
		if string.len(s)>1 then -- skip "/"
			if string.sub(s,-1) == "/" then
				s=string.sub(s,1,-2) -- remove trailing /
			end
		end
		
		for i=1,#ps do local v=ps[i]
			if v.cache.pubname==s then
				return nil -- no recursion
			end
		end
		
		return s
	end
	
	local p=ent
	while p do -- grab each page going upwards while it seems like a good idea
		ps[#ps+1]=p
		local s=check(p)
		if s then
			p=pages.cache_find_by_pubname(srv,s)
		else
			p=nil
		end
	end
	
-- start with the base wiki page, its kind of the main site everything
	p=wakapages.cache_get(srv,"/")
	ps[#ps+1]=p
	
	for i=#ps,1,-1 do local v=ps[i]
		v.chunks = wet_waka.text_to_chunks(v.cache.text) -- build this page only
		wet_waka.chunks_merge(chunks,v.chunks) -- merge all pages chunks
	end

	local crumbs={ {url="/",text="Home"} , {url="/blog",text="blog"} }
	crumbs[#crumbs+1]={url="/blog/"..ent.cache.id,text=ent.cache.id}
	srv.crumbs=crumbs
	
	if overload then
		local oc = wet_waka.text_to_chunks(overload.cache.text) -- build this overload page only
		wet_waka.chunks_merge(chunks,oc) -- replace given chunks with new chunks
	end

	local refined=wet_waka.refine_chunks(srv,chunks,{noblog=true}) -- build processed strings
	
	refined.body=refined.body or "" -- must have a body
	
	if not refined.title then -- build a title
		refined.title=string.sub(refined.body,1,80)
  	end
	
	return refined -- return the merged, processed chunks as an easy lookup table
end

-----------------------------------------------------------------------------
--
-- arg over is the name of a blogpost whoes chunks should overide all other chunks
-- this is useful to restyle a normal blog into something special
--
-- get a html block which is a handful of recent blog posts
-- and an optional css chunk to style this
--
-----------------------------------------------------------------------------
function recent_posts(srv,opts)--num,over,plate)
opts=opts or {}

local num=opts.num or 5

local get,put=make_get_put(srv)

	local t={}
	local css=""
	local list=pages.list(srv,{group=group,limit=num,layer=LAYER_PUBLISHED,sort="pubdate"})
	
	if opts.over and type(opts.over)=="string" then
		opts.over=pages.cache_find_by_pubname(srv,opts.over)
	else
		opts.over=nil
	end 
	
	for i,v in ipairs(list) do
	
		local refined=bubble(srv,v,opts.over) -- this gets parent entities

-- bad hardcoded, need to fix
		refined.link="/blog" .. v.cache.pubname
		refined.pubdate=(os.date("%Y-%m-%d %H:%M:%S",v.cache.pubdate))
		refined.it=v.cache
		
		if type(opts.hook) == "function" then
			opts.hook(refined)
		end

		local text=get(macro_replace(refined[opts.plate or ""] or refined.plate_wrap or refined.plate_post or "{body}",refined))
		
		if refined.css then css=refined.css end -- need to pass out some css too
		
		t[#t+1]=text
	end
	
	return table.concat(t),css
		
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
	if srv.url_slash[srv.url_slash_idx+0]=="" and srv.url_slash[srv.url_slash_idx+1]=="admin" then
		return serv_admin(srv)
	end
	
local sess,user=users.get_viewer_session(srv)
local get,put=make_get_put(srv)

	local ext -- an extension if any
	local aa={}
	for i=srv.url_slash_idx,#srv.url_slash do
		aa[#aa+1]=srv.url_slash[ i ]
	end
--	if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash

	if aa[#aa] and aa[#aa]~="" then
		local ap=str_split(".",aa[#aa])
		if #ap>1 and ap[#ap] then
			if ap[#ap]=="atom" then -- the pages in atom wrapper
				ext="atom"
			elseif ap[#ap]=="data" then -- just this pages raw data as text
				ext="data"
			elseif ap[#ap]=="dbg" then -- a debug json dump of data(inherited)
				ext="dbg"
			end
			if ext then
				ap[#ap]=nil
				aa[#aa]=table.concat(ap,".")
--				if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash we may have just created
			end
		end
	end
	
	
	local group
	local page
	local hash
	
	if aa[1] then
		local n=tonumber(aa[1]) or 0
		if aa[1]==tostring(n) then  -- lookup by id only?
			hash=n
		end
	end
	
	if not hash then
		if #aa > 1 then
			page=aa[#aa]
			aa[#aa]=nil
			group="/"..table.concat(aa,"/").."/"
		elseif #aa == 1 then
			page=aa[1]
			group="/"
		else
			page=""
			group="/"
		end
	end

	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv.headers.Referer and string.sub(srv.headers.Referer,1,string.len(srv.url))==srv.url then
		for i,v in pairs(srv.posts) do
			posts[i]=v
--			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	
	local function atom_escape(s)
	
		return string.gsub(s, "([%&%<])",
			function(c)
				if c=="&" then return "&amp;" end
				if c=="<" then return "&lt;" end
				return c
			end)
	end
	
	if page=="" then -- a list
		
		if ext=="atom" then -- an atom feed
		
			local list=pages.list(srv,{group=group,limit=23,layer=LAYER_PUBLISHED,sort="pubdate"})
			
			local updated=0
			local author_name=""
			if list[1] then
				updated=list[1].cache.pubdate
				author_name=list[1].cache.author_name
			end
			
			updated=os.date("%Y-%m-%dT%H:%M:%SZ",updated)
			srv.set_mimetype("application/atom+xml; charset=UTF-8")
			put("blog_atom_head",{title="blog",updated=updated,author_name=author_name})
			for i,v in ipairs(list) do
			
				local refined=bubble(srv,v) -- this gets parent entities
				local text=get(macro_replace(refined.plate_post or "{body}",refined))
				text=text..[[<script type="text/javascript" src="]]..srv.url_domain..[[/note/import/blog]]..v.cache.pubname..[[.js"></script>]]
				put("blog_atom_item",{it=v.cache,refined=refined,text=atom_escape(text)})
			end
			put("blog_atom_foot",{})
			
		
		else
			local list=pages.list(srv,{group=group,limit=10,layer=LAYER_PUBLISHED,sort="pubdate"})
			local refined
			if list[1] then
				refined=bubble(srv,list[1]) -- this gets parent entities
			end
			local css=refined and refined.css
			srv.set_mimetype("text/html; charset=UTF-8")
			put("header",{title="blog : "..group..page,css=css,
				H={sess=sess,user=user},
				adminbar=get("blog_admin_links",{user=user})})
		
			local refined
			local ss={}
			for i,v in ipairs(list) do
			
				refined=bubble(srv,v) -- this gets parent entities
				
				refined.link=srv.url_local:sub(1,-2) .. v.cache.pubname
				refined.pubdate=(os.date("%Y-%m-%d %H:%M:%S",v.cache.pubdate))
				refined.it=v.cache
				local text=get(macro_replace(refined.plate_wrap or "{body}",refined))
				ss[#ss+1]=text
			end
			
			if refined then
--				refined.title=""
				refined.body=table.concat(ss)
				put(macro_replace(refined.plate or "{body}",refined))
			end
			
			put("footer")
		end
		
	else -- a single page
	
		local ent
		if hash then -- by id only
			ent=pages.get(srv,hash)
		else
			ent=pages.cache_find_by_pubname(srv,group..page)
		end
		if ent and ent.cache.layer==LAYER_PUBLISHED then -- must be published
		
			local refined=bubble(srv,ent) -- this gets parent entities
			refined.link=srv.url_local:sub(1,-2) .. ent.cache.pubname
			refined.pubdate=(os.date("%Y-%m-%d %H:%M:%S",ent.cache.pubdate))
			refined.it=ent.cache
			
			if ext=="dbg" then -- dump out all the bubbled refined as json

				srv.set_mimetype("text/plain; charset=UTF-8")
				put( json.encode(refined) )
			
			else
			
				local text=get(macro_replace(refined.plate_page or refined.plate_post or "{body}",refined))

				srv.set_mimetype("text/html; charset=UTF-8")
				put("header",{title=refined.title,
					css=refined.css,
					H={sess=sess,user=user},
					adminbar=get("blog_admin_links",{it=ent.cache,user=user}),
					})

--				refined.title=""
				refined.body=text
				put(macro_replace(refined.plate or "{body}",refined))
				
				local ret=comments.build(srv,{title=refined.title,url=refined.link,posts=posts,get=get,put=put,sess=sess,user=user})
				
				if ret and ret.count then
					if ret.count~=ent.cache.comment_count then -- need to update cached number of comments
						pages.update(srv,ent,function(srv,e) e.cache.comment_count=ret.count return true end)
					end
				end

				put("footer")
				
			end
		end			
	end
	
end


-----------------------------------------------------------------------------
--
-- handle admin special pages/lists
--
-----------------------------------------------------------------------------
function serv_admin(srv)
local sess,user=users.get_viewer_session(srv)
local get,put=make_get_put(srv)

	if not( user and user.cache and user.cache.admin ) then -- adminfail
		return false
	end

local output_que={} -- delayed page content

	local function que(a,b) -- que
		output_que[#output_que+1]=get(a,b)
	end

	local css=css
	
	
	local posts={} -- remove any gunk from the posts input
	if srv.method=="POST" and srv.headers.Referer and srv.headers.Referer==srv.url then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	for i,v in pairs({"group","submit","pubname","layer"}) do
		if posts[v] then posts[v]=trim(posts[v]) end
	end
	for i,v in pairs({"layer"}) do
		if posts[v] then posts[v]=tonumber(posts[v]) end
	end

	local cmd=srv.url_slash[srv.url_slash_idx+2]

	if cmd=="pages" then
	
		local list=pages.list(srv,{sort="updated"})
		
		que("blog_admin_head",{})
		for i=1,#list do local v=list[i]
			local chunks=wet_waka.text_to_chunks(v.cache.text)
			que("blog_admin_item",{it=v.cache,chunks=chunks})
		end
		que("blog_admin_foot",{})

	elseif cmd=="edit" then
	
		local ent
		
		local group,name=get_page_name(srv.url_slash,srv.url_slash_idx+3)
		
		if group=="/$hash/" then -- edit by raw id
			ent=pages.get(srv,tonumber(name) or 0)
		elseif name=="$newpage" then
			ent=nil
		else 
			ent=pages.cache_find_by_pubname(srv,group..name)
		end
		
		if not ent then -- make a new ent but do not write it to the database unless it needs an id
		
			ent=pages.create(srv)
			ent.cache.author=user.cache.email
			ent.cache.group=group
			ent.cache.pubname=group..name
			ent.cache.layer=LAYER_DRAFT
			ent.cache.text=[[#title

The #title of your post.

#body

This is the #body of your post and can contain any html you wish.

]]
			if name=="$newpage" then -- create it now so we can give it an id
				pages.put(srv,ent) 
				ent.cache.pubname=group..ent.key.id
				pages.put(srv,ent)
				return srv.redirect(srv.url_base.."/admin/edit/$hash/"..ent.key.id)
			end
			
		end
		

		if posts.text or posts.submit then -- we wish to make an edit or create a new page
-- if two people edit a page at the same time, one edit will be lost
-- this is however a blog, you should not need to cope with that problem :)

			ent.cache.author=user.cache.email
			ent.cache.author_name=user.cache.name
			for i,v in pairs({"text","group","pubname","layer"}) do -- can change these parts
				if posts[v] then ent.cache[v]=posts[v] end
			end
			ent.cache.updated=srv.time
					
			if user and user.cache and user.cache.admin then -- admin only, so less need to validate inputs
				if		posts.submit=="Save" or
						posts.submit=="Publish" or
						posts.submit=="UnPublish" then -- save page to database
					
					if posts.submit=="Publish" then posts.layer=LAYER_PUBLISHED end
					if posts.submit=="UnPublish" then posts.layer=LAYER_DRAFT end
					ent.cache.layer=posts.layer or ent.cache.layer
					
					pages.put(srv,ent)
				end
			end
			
		end
		
		local publish="Publish"
		if ent.cache.layer==LAYER_PUBLISHED then publish="UnPublish" end
		que("blog_edit_form",{it=ent.cache,publish=publish,url=url})
		
		local refined=bubble(srv,ent) -- this gets parent entities
		que(macro_replace(refined.plate or "{body}",refined))
		css=refined.css

	
	else -- default
	
		

	end
	
	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="blog : admin",css=css,
		H={sess=sess,user=user},
		adminbar=get("blog_admin_links",{user=user})})
	
	for i,v in ipairs(output_que) do
		put(v)
	end
	
	put("footer")
	
end
