
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

local goo=require("port.goo")

local wet_waka=require("wetgenes.waka")

local d_sess =require("dumid.sess")
local d_users=require("dumid.users")
local d_nags=require("dumid.nags")


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
	
	ps[#ps+1]=ent
	
-- and the wiki pages for style, should fix this to use urls

	local p=wakapages.get(srv,"/blog")
	ps[#ps+1]=p
	p=wakapages.get(srv,"/")
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
-- turn an entity into a chunk ready to be turned into a string via a plate
--
-----------------------------------------------------------------------------
function chunk_prepare(srv,ent,opts)
opts=opts or {}

	local c=ent.cache

	local plink,purl=d_users.get_profile_link(c.author)
	
	local refined=bubble(srv,ent) -- this gets parent entities
	
	for i,v in pairs(c) do refined[i]=v end	c=refined -- merge with the cache
	
	if type(opts.hook) == "function" then -- fix up each item?
		opts.hook(refined,{class="blog_refined"})
	end
	
	c.title=macro_replace("{title}",refined) -- build title
	c.body=macro_replace("{body}",refined) -- and body from the blogs chunks only
	
	c.media=""

	c.link="/blog" .. c.pubname
	
--[[
	if not c.author_icon then -- need to update our user icon
		local author_icon = d_users.get_avatar_url(c.author)
		d_users.update(srv,ent,function(srv,e)
			e.cache.author_icon=author_icon
			return true
		end)
		c.author_icon=author_icon
	end
]]
	
	c.author_name=c.author_name
	c.author_icon=srv.url_domain..( c.author_icon or "" )
	c.author_link=purl or "http://google.com/search?q="..c.author_name
	
	c.date=os.date("%Y-%m-%d %H:%M:%S",c.created)

	if type(opts.hook) == "function" then -- fix up each item?
		opts.hook(c,{class="blog"})
	end

	return c	
end

-----------------------------------------------------------------------------
--
-- import some blog entries into the waka
--
-----------------------------------------------------------------------------
function chunk_import(srv,opts)
opts=opts or {}

local get,put=make_get_put(srv)

	local t={}
	local css=""
	local list=pages.list(srv,opts)

	local ret={}
	for i,v in pairs(opts) do ret[i]=v end -- copy opts into the return
	
--	if true then return ret end

	for i,v in ipairs(list) do
		local c=chunk_prepare(srv,v,opts)
		if c then ret[#ret+1]=c end
	end
	
	return ret
		
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
--function chunk_import(srv,opts) return recent_posts(srv,opts) end
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
	
		local c=chunk_prepare(srv,v,opts)
		
		css=c.css
		
		c.it=c
		if c then
			t[#t+1]=get(macro_replace(c[opts.plate or ""] or c.plate_wrap or c.plate_post or "{body}",c))
		end
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
local opts={}
local sess,user=d_sess.get_viewer_session(srv)
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
			
				local c=chunk_prepare(srv,v,opts)
				local text=get(macro_replace(c[opts.plate or ""] or c.plate_post or "{body}",c))
				text=text..[[<script type="text/javascript" src="]]..srv.url_domain..[[/note/import/blog]]..v.cache.pubname..[[.js"></script>]]
				put("blog_atom_item",{it=v.cache,refined=c,text=atom_escape(text)})
			end
			put("blog_atom_foot",{})
			
		
		else
			local list=pages.list(srv,{group=group,limit=10,layer=LAYER_PUBLISHED,sort="pubdate"})
			local refined
			if list[1] then -- get css?
				refined=chunk_prepare(srv,list[1],opts)
			end
			local css=refined and refined.css
			srv.set_mimetype("text/html; charset=UTF-8")
			put("header",{title="blog : "..group..page,css=css,
				H={sess=sess,user=user},
				adminbar=get("blog_admin_links",{user=user})})
		
			local ss={}
			for i,v in ipairs(list) do
			
				local c=chunk_prepare(srv,v,opts)
				refined.it=c

				local text=get(macro_replace(c[opts.plate or ""] or c.plate_wrap or "{it.body}",refined))
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
		
			local refined=chunk_prepare(srv,ent,opts)
			refined.it=refined
			
			if ext=="dbg" then -- dump out all the bubbled refined as json

				srv.set_mimetype("text/plain; charset=UTF-8")
				put( json.encode(refined) )
			
			else
			
				local text=get(macro_replace(refined.plate_page or refined.plate_post or "{it.body}",refined))

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
local sess,user=d_sess.get_viewer_session(srv)
local get,put=make_get_put(srv)

	if not( user and user.cache and user.cache.admin ) then
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
			ent.cache.author=user.cache.id
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

			ent.cache.author=user.cache.id
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
		
		local refined=chunk_prepare(srv,ent,opts)
		refined.it=refined
		local blog_text=macro_replace(refined.plate or "<h1>{it.title}</h1>{it.body}",refined)
		que(blog_text)
		css=refined.css

		if user and user.cache and user.cache.admin then -- admin only, so less need to validate inputs
				
			if posts.submit=="Publish" then -- build a nag when we click publish
				
-- get or reuse a short url from goo.gl

				local long_url=srv.url_base..ent.cache.pubname:sub(2)
				local short_url
				
				if ent.cache.short_url then
					short_url=ent.cache.short_url
				else
					short_url=goo.shorten(long_url)
					pages.update(srv,ent,function(srv,ent)
							ent.cache.short_url=short_url
							return true
						end)
				end

-- finally add a nag to pester us to twat it
				local nag={}
				
				nag.id="blog"
				nag.url=long_url
				nag.short_url=short_url
				
				local s=blog_text
				s=s:gsub("(%b<>)","") -- kill any html tags
				s=s:gsub("%s+"," ") -- replace any range of whitespace with a single space
				s=wet_string.trim(s)
				s=s:sub(1,(140-1)-#short_url) -- reduce to 140ish chars, dont care if we chop a word
				s=wet_string.trim(s)
				
				nag.c140_base=s -- some base text without the url
				nag.c140=s.." "..short_url -- add a link on the end
				
				d_nags.save(srv,srv.sess,nag)
				
			end
		end
	
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
