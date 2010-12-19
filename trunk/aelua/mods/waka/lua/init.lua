
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

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=users.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)

local display_edit
local display_edit_only=false
local ext

	local aa={}
	for i=srv.url_slash_idx,#srv.url_slash do
		aa[#aa+1]=srv.url_slash[ i ]
	end
	if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash
	
	if aa[1]=="" and aa[2]=="admin" then
		return serv_admin(srv)
	end
	
	if aa[#aa] then
		local ap=str_split(".",aa[#aa])
		if ap[#ap] then
			if ap[#ap]=="css" then -- css
				ext="css"
			elseif ap[#ap]=="html" then -- just the pages html 
				ext="html"
			elseif ap[#ap]=="data" then -- just this pages raw page data as text
				ext="data"
			elseif ap[#ap]=="frame" then -- special version of this page intended to be embeded in an iframe
				ext="frame"
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
	local crumbs=" <a href=\"/\">home</a> / <a href=\""..url.."\">"..srv.slash.."</a> "
	for i,v in ipairs(aa) do
		baseurl=url
		url=url..v
		crumbs=crumbs.." / <a href=\""..url.."\">"..v.."</a> "
		url=url.."/"
	end
	local pagename="/"..table.concat(aa,"/")
	local url=srv.url_base..table.concat(aa,"/")
	local url_local=srv.url_local..table.concat(aa,"/")
	if ext then url=url.."."..ext end -- this is a page extension
	
	if srv.url~=url then -- force a redirect to the perfect page name with or without a trailing slash
		return srv.redirect(url)
	end
	
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv.headers.Referer and string.sub(srv.headers.Referer,1,string.len(url))==url then
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
			if posts.submit=="Save" then -- save page to database
				if posts.text then
					local chunks=wet_waka.text_to_chunks(posts.text)
					pages.edit(srv,pagename,
						{
							text=posts.text,
							author=user.cache.email,
							note=(chunks.note and chunks.note.text) or "",
						})
				end
			else
				display_edit=get("waka_edit_form",{text=page.cache.text}) -- still editing
				if (srv.vars.cmd and srv.vars.cmd=="edit") then display_edit_only=true end
			end
		end
	end
	
	
	local ps={}
	local p=page
	ps[1]=p
	while p.cache.group ~= p.cache.id do -- grab each page going upwards
		p=pages.manifest(srv,p.cache.group)
		ps[#ps+1]=p
	end

	local chunks={}	-- merge all pages and their parents into this
	for i=#ps,1,-1 do local v=ps[i]
		v.chunks = wet_waka.text_to_chunks(v.cache.text) -- build this page only
		wet_waka.chunks_merge(chunks,v.chunks) -- merge all pages chunks
	end

	
	local form=wet_waka.form_chunks(srv,chunks) -- build processed strings

	local pageopts={
		flame="on",
	}
	if chunks.opts then
		for n,s in pairs(chunks.opts.opts) do
			pageopts[n]=s
		end
	end

-- disable comments if page is not saved to the database IE a MISSING PAGE	
	if ps[1].key.notsaved then
		pageopts.flame="off"
	end


	if ext=="css" then -- css only
	
		srv.set_mimetype("text/css; charset=UTF-8")
		srv.set_header("Cache-Control","public") -- allow caching of css page
		srv.put(form.css or "")
		
	elseif ext=="frame" then -- special iframe render mode
	
		srv.set_mimetype("text/html; charset=UTF-8")
		put(macro_replace(form.frame or [[
		<h1>{title}</h1>
		{body}
		]],form))
		
	elseif ext=="data" then -- raw chunk data
	
		srv.set_mimetype("text/plain; charset=UTF-8")
		srv.put(page.cache.text or "")
		
	else
	
		srv.set_mimetype("text/html; charset=UTF-8")
		local css
		if form.css then css=macro_replace(form.css,form) end
		
		put("header",{title="waka : "..pagename:sub(2),css=css--[[,css=url..".css"]]})
		
		put("waka_bar",{crumbs=crumbs,page=pagename})
		
		if display_edit then srv.put(display_edit) end
		
		if not display_edit_only then
		
			put(macro_replace(form.plate or [[
			<h1>{title}</h1>
			{body}
			]],form))
			
			if pageopts.flame=="on" then -- add comments to this page
				comments.build(srv,{title=form.title or pagename,url=url_local,posts=posts,get=get,put=put,sess=sess,user=user})
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
local sess,user=users.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)

	local crumbs=" <a href=\"/\">home</a> / <a href=\""..srv.url_base.."\">"..srv.slash.."</a> "
	crumbs=crumbs.." / <a href=\""..srv.url_base.."/admin\">admin</a> "
	local cmd= srv.url_slash[ srv.url_slash_idx+2]

	if not ( user and user.cache and user.cache.admin ) then -- not admin, no access
		put("header",{title="waka : admin"})
		put("waka_bar",{crumbs=crumbs})
		put("footer")
		return
	end
	
	
	put("header",{title="waka : admin"})

	put("waka_bar",{crumbs=crumbs})

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
