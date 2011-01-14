
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
local html=require("note.html")
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
local opts_mods_note=(opts and opts.mods and opts.mods.note) or {}

module("note")

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
local function make_url(srv)
	local url=srv.url_base
	if url:sub(-1)=="/" then url=url:sub(1,-2) end -- trim any trailing /
	return url
end
local function make_posts(srv)
	local url=make_url(srv)
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing any post params
	if srv.method=="POST" and srv.headers.Referer and string.sub(srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(srv.posts) do
			posts[i]=v
		end
	end
	if posts.submit then posts.submit=trim(posts.submit) end
	return posts
end

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)

	local cmd=srv.url_slash[srv.url_slash_idx+0]
	if cmd=="import" then
		return serv_import(srv)
	end

local sess,user=users.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)
local posts=make_posts(srv)

	
	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="notes ",H={user=user,sess=sess}})

--	comments.build(srv,{url="/note",posts=posts,get=get,put=put,sess=sess,user=user})
	
--[[
	local t=users.email_to_avatar_url("15071645@id.twitter.com")
	local t=users.email_to_avatar_url("kriss2@xixs.com")
	put('<img src="{src}">',{src=t})
]]

	put([[
<div class="wetnote_ticker">{text}</div>
]],	{
		text=comments.recent_to_html(srv, comments.get_recent(srv,50) ),
	})

	
	put("footer")
end


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv_import(srv)

local sess,user=users.get_viewer_session(srv)
local put=make_put(srv)
local get=make_get(srv)
local posts=make_posts(srv)

	local ext
	local aa={}
	for i=srv.url_slash_idx+1,#srv.url_slash do
		aa[#aa+1]=srv.url_slash[i]
	end
	if aa[#aa]=="" then aa[#aa]=nil end-- kill any trailing slash
	if aa[#aa] then
		local ap=str_split(".",aa[#aa])
		if ap[#ap] then
			if ap[#ap]=="js" then -- javascript embed
				ext="js"
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

	local note_url="/"..table.concat(aa,"/") -- this is the url we are talking about

	if ext=="js" then
		srv.set_mimetype("text/javascript; charset=UTF-8")
		
		local out={}
		local newput=function(a,b)
			out[#out+1]=get(a,b)
		end
		comments.build(srv,{url=note_url,posts={},get=get,put=newput,sess=sess,user=user,linkonly=true})
		local s=table.concat(out) -- this is the html string we wish to insert

local function js_encode(str)
    return string.gsub(str, "([\"\'\t\n])", function(c)
        return string.format("\\x%02x", string.byte(c))
    end)
end		
		put([[
var div = document.createElement('div');
div.id='{url}';
div.innerHTML='{str}';

var scripts = document.getElementsByTagName('script');  
for(var i=0; i<scripts.length; i++)  
{  
    if(scripts[i].src == '{url}')  
    {  
		scripts[i].parentNode.insertBefore(div, scripts[i]);  
        break;  
    }  
}
]],
{
	url=srv.url,
	str=js_encode(s),
})
		
	else
		srv.set_mimetype("text/html; charset=UTF-8")
		put("header",{title="import notes ",user=user,sess=sess,bar=""})
		

		put("footer",{about="",report="",bar="",})
	end
end
