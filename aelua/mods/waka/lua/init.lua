
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

-- require all the module sub parts
local html=require("waka.html")
local pages=require("waka.pages")
local edits=require("waka.edits")



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
-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=users.get_viewer_session(srv)
local put=make_put(srv)

	local aa={}
	for i=srv.url_slash_idx,#srv.url_slash do
		aa[#aa+1]=srv.url_slash[ i ]
	end
	if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash
	local url=string.sub(srv.url_base,1,#srv.url_base-1)
	local baseurl=url
	local crumbs=" <a href=\"/\">home</a> / <a href=\""..url.."\">"..srv.slash.."</a> "
	for i,v in ipairs(aa) do
		baseurl=url
		url=url.."/"..v
		crumbs=crumbs.." / <a href=\""..url.."\">"..v.."</a> "
	end
	local pagename="/"..table.concat(aa,"/")
	
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if srv.method=="POST" and srv.headers.Referer and string.sub(srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(srv.posts) do
			posts[i]=v
--			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	
	put("header",{title="waka : "..pagename:sub(2)})
	
	put("waka_bar",{crumbs=crumbs,page=pagename})
	
	local page=pages.manifest(srv,pagename)

	if posts.text or posts.submit then
	
		if posts.text then -- replace the page with what was in the form?
			page.cache.text=posts.text
		end
		
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
			put("waka_edit_form",{text=page.cache.text}) -- still editing
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
	
	local form={}
	for i,v in ipairs(chunks) do -- do basic process of all of the page chunks into their prefered form 
		local s=""
		if v.opts.form=="raw" then -- predefined, use exactly as is, html
			s=v.text
		elseif v.opts.form=="trim" then -- like raw but with leading and trailing whitespace removed
			s=trim(v.text)
		else
			s=wet_waka.chunk_to_html(v,baseurl) -- default to waka
		end
		form[v.name]=s
	end
	
	for recursive=1,2 do -- chunks may include chunks which may include chunks, but only 2 deep
		for i,v in pairs(form) do -- include chunks data into each other {}
			form[i]=replace(v,form) -- later chunks can also include earlier chunks
		end
	end
	
	
	put(replace(form.plate or [[
	<h1>{title}</h1>
	{body}
	]],form))
	
--	put(tostring(srv))
	
	put("footer")
end

