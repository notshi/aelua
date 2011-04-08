
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_sandbox=require("wetgenes.sandbox")

local wet_string=require("wetgenes.string")
local replace=wet_string.replace
local macro_replace=wet_string.macro_replace
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")
local d_sess =require("dumid.sess")

-- require all the module sub parts
local html=require("waka.html")
local pages=require("waka.pages")
local edits=require("waka.edits")

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
local setfenv=setfenv
local pcall=pcall

--
-- Which can be overeiden in the global table opts
--
local opts_mods_waka={}
if opts and opts.mods and opts.mods.waka then opts_mods_waka=opts.mods.waka end

module("waka")
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

hooks={
	changed={},
}

-----------------------------------------------------------------------------
--
-- handle admin special pages/lists
--
-----------------------------------------------------------------------------
function add_changed_hook(pat,func)

	hooks.changed[func]=pat -- use func as the key
	
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

local display_edit
local display_edit_only=false
local ext

	local aa={}
	if srv.vars.page then -- overload with this forced pagename
		if srv.vars.page~="" then
			aa=str_split("/",srv.vars.page,true)
		end
	else
		for i=srv.url_slash_idx,#srv.url_slash do
			aa[#aa+1]=srv.url_slash[ i ]
		end
	end
	if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash
	
	if aa[1]=="" and aa[2]=="admin" then
		return serv_admin(srv)
	end
	
	if aa[#aa] then
		local ap=str_split(".",aa[#aa])
		if #ap>1 and ap[#ap] then
			if ap[#ap]=="css" then -- css
				ext="css"
			elseif ap[#ap]=="html" then -- just the pages html 
				ext="html"
			elseif ap[#ap]=="data" then -- just this pages raw page data as text
				ext="data"
			elseif ap[#ap]=="frame" then -- special version of this page intended to be embeded in an iframe
				ext="frame"
			elseif ap[#ap]=="dbg" then -- a debug json dump of data(inherited)
				ext="dbg"
			end
			if ext then
				ap[#ap]=nil
				aa[#aa]=table.concat(ap,".")
				if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash we may have just created
			end
		end
	end
	
	local url=srv.url_base
	local baseurl=url
	local crumbs={ {url=url,text="Home"}}
	for i,v in ipairs(aa) do
		baseurl=url
		url=url..v
		crumbs[#crumbs+1]={url=url,text=v}
		url=url.."/"
	end
	local pagename="/"..table.concat(aa,"/")
	local url=srv.url_base..table.concat(aa,"/")
	local url_local=srv.url_local..table.concat(aa,"/")
	if ext then url=url.."."..ext end -- this is a page extension
	
	if not srv.vars.page and srv.url~=url then -- force a redirect to the perfect page name with or without a trailing slash
		return srv.redirect(url)
	end

	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this *SITE* before allowing post params
	-- this is less of a check than normal since we are now lax with wiki edit urls
	if srv.method=="POST" and srv.headers.Referer and string.sub(srv.headers.Referer,1,string.len(srv.url_base))==srv.url_base then
		for i,v in pairs(srv.posts) do
			posts[i]=v
--			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	
	local page=pages.manifest(srv,pagename)


	if posts.text or posts.submit or (srv.vars.cmd and srv.vars.cmd=="edit") then
	
		if posts.text then -- replace the page with what was in the form?
			page.cache.text=posts.text
		end
		
		if user and user.cache and user.cache.admin then -- admin
			if posts.submit=="Save" or posts.submit=="Write" then -- save page to database
				if posts.text then
					local chunks=wet_waka.text_to_chunks(posts.text)
					local e=pages.edit(srv,pagename,
						{
							text=posts.text,
							author=user.cache.id,
							note=(chunks.note and chunks.note.text) or "",
						})
					for f,p in pairs(hooks.changed) do -- update hooks?
						if string.find(pagename,p) then
							f(srv,e)
						end
					end
				end
			end
			
			if posts.submit~="Save" then -- keep editing
				display_edit=get("waka_edit_form",{text=page.cache.text}) -- still editing
				if (srv.vars.cmd and srv.vars.cmd=="edit") then display_edit_only=true end
			end
			
		end
	end
	
	
	local ps={}
	local p=page
	ps[1]=p
	while p.cache.group ~= p.cache.id do -- grab each parent page going upwards
		p=pages.manifest(srv,p.cache.group)
		ps[#ps+1]=p
	end

	local chunks={}	-- merge all pages and their parents into this
	for i=#ps,1,-1 do local v=ps[i]
		v.chunks = wet_waka.text_to_chunks(v.cache.text) -- build this page only
		wet_waka.chunks_merge(chunks,v.chunks) -- merge all pages chunks
	end

	
	local pageopts={
		flame="on",
	}
	srv.pageopts=pageopts -- keep the page options here
	
	if chunks.opts then
		for n,s in pairs(chunks.opts.opts) do
			pageopts[n]=s
		end
	end
	
	pageopts.vars=srv.vars -- page code is allowed access to these bits
	pageopts.url           = srv.url
	pageopts.url_slash     = srv.url_slash
	pageopts.url_slash_idx = srv.url_slash_idx
	
	pageopts.limit=math.floor(tonumber(pageopts.limit or 10) or 10)
	if pageopts.limit<1 then pageopts.limit=1 end
	
	pageopts.offset=math.floor(tonumber(srv.vars.offset or 0) or 0)
	if pageopts.offset<0 then pageopts.offset=0 end
	
	pageopts.offset_next=pageopts.offset+pageopts.limit
	pageopts.offset_prev=pageopts.offset-pageopts.limit
	if pageopts.offset_prev<0 then pageopts.offset_prev=0 end
	

	local refined={}
	if not display_edit_only then
		refined=wet_waka.refine_chunks(srv,chunks,pageopts) -- build processed strings
	end
	
	if pageopts.redirect then -- we may force a redirect here
		return srv.redirect(pageopts.redirect)
	end

-- disable comments if page is not saved to the database IE a MISSING PAGE	
-- except when page has been locked upstream
	if ps[1].key.notsaved and pageopts.lock~="on" then
		pageopts.flame="off"
	end

-- disable comments if this is not the real page address
	if srv.vars.page then pageopts.flame="off" end

	if ext=="css" then -- css only
	
		srv.set_mimetype("text/css; charset=UTF-8")
		srv.set_header("Cache-Control","public") -- allow caching of page
		srv.set_header("Expires",os.date("%a, %d %b %Y %H:%M:%S GMT",os.time()+(60*60))) -- one hour cache
		srv.put(refined.css or "")
		
	elseif ext=="frame" then -- special iframe render mode
	
		srv.set_mimetype("text/html; charset=UTF-8")
		put(macro_replace(refined.frame or [[
		<h1>{title}</h1>
		{body}
		]],refined))
		
	elseif ext=="data" then -- raw chunk data
	
		srv.set_mimetype("text/plain; charset=UTF-8")
		srv.put(page.cache.text or "")
		
	elseif ext=="dbg" then -- dump out all the bubbled chunks as json

		srv.set_mimetype("text/plain; charset=UTF-8")
		put( json.encode(chunks) )
			
	else
	
		srv.set_mimetype("text/html; charset=UTF-8")
		local css
		if refined.css then css=macro_replace(refined.css,refined) end
		
		put("header",{title=refined.title,css=css--[[,css=url..".css"]],crumbs=crumbs})
		
		put("waka_bar",{page=pagename})
		
		if display_edit then srv.put(display_edit) end
		
		if not display_edit_only then
		
			put(macro_replace(refined.plate or [[
			<h1>{title}</h1>
			{body}
			]],refined))
			
			if pageopts.flame=="on" then -- add comments to this page
				comments.build(srv,{title=refined.title or pagename,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user})
			end
			
		end
		
		put("footer")
	end
end



-----------------------------------------------------------------------------
--
-- handle admin special pages/lists
--
-----------------------------------------------------------------------------
function serv_admin(srv)
local sess,user=d_sess.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)

	if not( user and user.cache and user.cache.admin ) then -- adminfail
		return false
	end

	local cmd= srv.url_slash[ srv.url_slash_idx+2]
	
	
	put("header",{title="waka : admin"})

	put("waka_bar",{})

	if cmd=="pages" then
	
		local list=pages.list(srv,{})
		
		for i=1,#list do local v=list[i]
		
			local dat={
				page=v.cache,
				page_name=v.cache.id,
				url_base=srv.url_base:sub(1,-2),
				time=os.date("%Y/%m/%d %H:%M:%S",v.cache.updated),
				author=(v.cache.edit.author or "")
				}
			put([[
<a style="position:relative;display:block;width:960px" href="{url_base}{page_name}">
{time} : {page_name} 
<span style="position:absolute;right:0px">{author}</span>
</a>]],dat)

		end
	
	elseif cmd=="edits" then
	
		local list=edits.list(srv,{})
		
		for i=1,#list do local v=list[i]
		
			local dat={
				page=v.cache,
				page_name=v.cache.page,
				url_base=srv.url_base:sub(1,-2),
				time=os.date("%Y/%m/%d %H:%M:%S",v.cache.time),
				author=(v.cache.author or "")
				}
			put([[
<a style="position:relative;display:block;width:960px" href="{url_base}{page_name}">
{time} : {page_name}
<span style="position:absolute;right:0px">{author}</span>
</a>]],dat)

		end
	else
	
			put([[
			<a href="{srv.url_base}/admin/pages"> view all pages </a><br/>
			<a href="{srv.url_base}/admin/edits"> view all edits </a><br/>
]],{})

	end
	

	put("footer")
	
end
