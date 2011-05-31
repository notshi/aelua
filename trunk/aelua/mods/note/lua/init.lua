
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
local d_users=require("dumid.users")
local d_sess=require("dumid.sess")

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
local function make_get_put(srv)
	return make_get(srv),make_put(srv)
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

local sess,user=d_Sess.get_viewer_session(srv)
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

local sess,user=d_sess.get_viewer_session(srv)
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
			elseif ap[#ap]=="atom" then -- rss feed
				ext="atom"
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


	if ext=="atom" then -- head comments only in feed, comments on comments are ignored
	
		local function atom_escape(s)

			return string.gsub(s, "([%&%<])",
				function(c)
					if c=="&" then return "&amp;" end
					if c=="<" then return "&lt;" end
					return c
				end)
		end

			local list=comments.list(srv,{csortdate="DESC",url=note_url,group=0}) -- get all comments
			
			local updated=0
			local author_name=""
			if list[1] then
				updated=list[1].cache.created
				author_name=list[1].cache.cache.user.name
			end
			
			updated=os.date("%Y-%m-%dT%H:%M:%SZ",updated)
			srv.set_mimetype("application/atom+xml; charset=UTF-8")
			put("note_atom_head",{title="notes",updated=updated,author_name=author_name})
			for i,v in ipairs(list) do
log(tostring(v.cache))				
				local text,vars=comments.build_get_comment(srv,{url=note_url,get=get},v.cache)
				
				vars.script=[[<script type="text/javascript" src="]]..srv.url_domain..[[/note/import]]..note_url..[[.js?wetnote=]]..v.cache.id..[["></script>]]
				put("note_atom_item",{
					it=v.cache,
					text=atom_escape(vars.media..vars.text..vars.script),
					title=atom_escape(vars.title),
					link=srv.url_domain..note_url.."#wetnote"..v.cache.id,
					})
			end
			put("note_atom_foot",{})

	elseif ext=="js" then
		srv.set_mimetype("text/javascript; charset=UTF-8")
		
		local out={}
		local newput=function(a,b)
			out[#out+1]=get(a,b)
		end
		local replyonly
		if srv.gets.wetnote then
			replyonly=tonumber(srv.gets.wetnote)
		end
		comments.build(srv,{url=note_url,posts={},get=get,put=newput,sess=sess,user=user,linkonly=true,replyonly=replyonly})
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

if (!document.getElementById('{css}'))
{
    var head  = document.getElementsByTagName('head')[0];
    var link  = document.createElement('link');
    link.id   = '{css}';
    link.rel  = 'stylesheet';
    link.type = 'text/css';
    link.href = '{css}';
    link.media = 'all';
    head.appendChild(link);
}

]],
{
	url=srv.url,
	str=js_encode(s),
	css=srv.url_domain.."/css/note/import.css"
})
		
	else
		srv.set_mimetype("text/html; charset=UTF-8")
		put("header",{title="import notes ",user=user,sess=sess,bar=""})
		

		put("footer",{about="",report="",bar="",})
	end
end


-----------------------------------------------------------------------------
--
-- get a html string which is a handful of recent comments,
--
-----------------------------------------------------------------------------
function chunk_import(srv,opts)
opts=opts or {}

local get,put=make_get_put(srv)

	local t={}
	local css=""
	local list=comments.list(srv,opts)

	local ret={}
	for i,v in pairs(opts) do ret[i]=v end -- copy opts into the return
	
	for i,v in ipairs(list) do
	
		local c=v.cache
		if c.cache.user then
		
			local media=""
			if c.media~=0 then
				media=[[<a href="/data/]]..c.media..[["><img src="]]..srv.url_domain..[[/thumbcache/460/345/data/]]..c.media..[[" class="wetnote_comment_img" /></a>]]
			end	
			local plink,purl=d_users.get_profile_link(c.cache.user.id)
			
			c.media=media -- img tag+link or ""
			
			c.title=""
			c.body=wet_waka.waka_to_html(c.text,{base_url="/",escape_html=true})
			
			c.link=c.url.."?wetnote="..c.id.."#wetnote"..c.id
			
			c.author_name=c.cache.user.name
			c.author_icon=srv.url_domain..( c.cache.avatar or d_users.get_avatar_url(c.cache.user) )		
			c.author_link=purl or "http://google.com/search?q="..c.cache.user.name
			
			c.date=os.date("%Y-%m-%d %H:%M:%S",c.created)
		
		
			if type(opts.hook) == "function" then -- fix up each item?
				opts.hook(v,{class="note"})
			end
			
			ret[#ret+1]=c

		end
	end
	
	return ret
		
end
