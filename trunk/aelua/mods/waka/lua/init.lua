
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")

-- require all the module sub parts
local html=require("waka.html")
local pages=require("waka.pages")



local math=math
local string=string
local table=table
local os=os

local ipairs=ipairs
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
	local url=string.sub(srv.url_base,1,#srv.url_base-1)
	local crumbs=" <a href=\"/\">home</a> / <a href=\""..url.."\">"..srv.slash.."</a> "
	if not aa[1] then aa[1]="" end
	for i,v in ipairs(aa) do
		url=url.."/"..v
		crumbs=crumbs.." / <a href=\""..url.."\">"..v.."</a> "
	end
	local page="/"..table.concat(aa,"/")
	
	put("header",{title="waka : "..page})
	
	put("waka_bar",{crumbs=crumbs,page=page})
	
	local page=pages.manifest(srv,page)
	local chunks=wet_waka.text_to_chunks(page.cache.text)
	put(tostring(chunks))

--	put(tostring(srv))
	
	put("footer")
end

