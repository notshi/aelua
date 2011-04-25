

local log=require("wetgenes.aelua.log").log

local sys=require("wetgenes.aelua.sys")
local waka=require("wetgenes.waka")
local users=require("wetgenes.aelua.users")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local table=table
local string=string
local math=math
local os=os

local pairs=pairs
local ipairs=ipairs
local tostring=tostring
local require=require

local opts=opts
local opts_html={}
if opts and opts.html then opts_html=opts.html end
opts_html.bar=opts_html.bar or "head"

module("base.html")


-----------------------------------------------------------------------------
--
-- turn a number of seconds into a rough duration
--
-----------------------------------------------------------------------------
function rough_english_duration(t)
	t=math.floor(t)
	if t>=2*365*24*60*60 then
		return math.floor(t/(365*24*60*60)).." years"
	elseif t>=2*30*24*60*60 then
		return math.floor(t/(30*24*60*60)).." months" -- approximate months
	elseif t>=2*7*24*60*60 then
		return math.floor(t/(7*24*60*60)).." weeks"
	elseif t>=2*24*60*60 then
		return math.floor(t/(24*60*60)).." days"
	elseif t>=2*60*60 then
		return math.floor(t/(60*60)).." hours"
	elseif t>=2*60 then
		return math.floor(t/(60)).." minutes"
	elseif t>=2 then
		return t.." seconds"
	elseif t==1 then
		return "1 second"
	else
		return "0 seconds"
	end
end

-----------------------------------------------------------------------------
--
-- turn an integer number into a string with three digit grouping
--
-----------------------------------------------------------------------------
function num_to_thousands(n)
	local p=math.floor(n) -- remove the fractions
	if p<0 then p=-p end -- remove the sign
	local s=string.format("%d",p) -- force format integer part only?
	local len=string.len(s) -- total length of number
	local skip=len%3 -- size of first batch
	local t={}
	if skip>0 then -- 1 or 2 digits
		t[#t+1]=string.sub(s,1,skip)
	end
	for i=skip,len-3,3 do -- batches of 3 digits
		t[#t+1]=string.sub(s,i+1,i+3)
	end
	local s=table.concat(t,",") -- join it back together with commas every 3 digits
	if n<0 then return "-"..s else return s end -- put the sign back and return it
end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
header=function(d)

	if opts_html.bar=="head" then
		d.bar=d.bar or get_html("aelua_bar",d)
	end
	d.bar=d.bar or ""
	
	d.extra=(d.srv and d.srv.extra or "") .. ( d.extra or "" )
	
	d.favicon="/favicon.ico"
	d.blogtitle="blog"
	d.blogurl="/blog/.atom"


	for _,v in ipairs{d.srv or {},d,opts.head or {} } do
		
		if v.extra_css then
			for i,v in ipairs(v.extra_css) do
				d.extra=d.extra..[[<link rel="stylesheet" type="text/css" href="]]..v..[[" />
]]
			end
		end
		if v.extra_js then
			for i,v in ipairs(v.extra_js) do
				d.extra=d.extra..[[<script type="text/javascript" src="]]..v..[["></script>
]]
			end
		end
		if v.css then --embed some raw css
			d.extra=d.extra.."<style type=\"text/css\">"..v.css.."</style>"
		end
		
		if v.favicon then --favicon link
			d.favicon=v.favicon
		end
		if v.blogtitle then --blogtitle
			d.blogtitle=v.blogtitle
		end
		if v.blogurl then --blogurl
			d.blogurl=v.blogurl
		end
	end
	
	d.jquery_js="http://ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js"
	d.jquery_ui_js="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.2/jquery-ui.min.js"
	d.swfobject_js="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"
	d.jquery_validate_js="http://ajax.microsoft.com/ajax/jQuery.Validate/1.6/jQuery.Validate.min.js"
	
	if d.srv.url_slash[3]=="host.local:8080" then -- a local shop only servs local people
		d.jquery_js="/js/base/jquery-1.4.3.js"
		d.jquery_ui_js="/js/base/jquery-ui-1.8.2.custom.min.js"
		d.swfobject_js="/js/base/swfobject.js"
		d.jquery_validate_js="/js/base/jquery.validate.js"
	end
	
	d.all_min_js="/js/base/all.min.js"
		
	if not d.title then
		local crumbs=d.srv.crumbs
		local s
		for i=1,#crumbs do local v=crumbs[i]
			if v.title then
				if not s then s="" else s=s.." - " end
				s=s..v.title
			end
		end
		d.title=s
	end

	local p=get_plate_orig("header",
[[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head>

<title>{title}</title>

<link rel="alternate" type="application/atom+xml" title="{blogtitle}" href="{blogurl}" />

<link rel="shortcut icon" href="{favicon}" />

<link rel="stylesheet" type="text/css" href="/css/base/aelua.css" /> 
<link rel="stylesheet" type="text/css" href="/.css" /> 

<script type="text/javascript"> /* head.js embed loader only */
<!--
(function(a){var b=a.documentElement,c,d,e=[],f=[],g={},h={},i=a.createElement("script").async===true||"MozAppearance"in a.documentElement.style||window.opera;var j=window.head_conf&&head_conf.head||"head",k=window[j]=window[j]||function(){k.ready.apply(null,arguments)};var l=0,m=1,n=2,o=3;i?k.js=function(){var a=arguments,b=a[a.length-1],c=[];t(b)||(b=null),s(a,function(d,e){d!=b&&(d=r(d),c.push(d),x(d,b&&e==a.length-2?function(){u(c)&&p(b)}:null))});return k}:k.js=function(){var a=arguments,b=[].slice.call(a,1),d=b[0];if(!c){f.push(function(){k.js.apply(null,a)});return k}d?(s(b,function(a){t(a)||w(r(a))}),x(r(a[0]),t(d)?d:function(){k.js.apply(null,b)})):x(r(a[0]));return k},k.ready=function(a,b){if(a=="dom"){d?p(b):e.push(b);return k}t(a)&&(b=a,a="ALL");var c=h[a];if(c&&c.state==o||a=="ALL"&&u()&&d){p(b);return k}var f=g[a];f?f.push(b):f=g[a]=[b];return k},k.ready("dom",function(){c&&u()&&s(g.ALL,function(a){p(a)}),k.feature&&k.feature("domloaded",true)});function p(a){a._done||(a(),a._done=1)}function q(a){var b=a.split("/"),c=b[b.length-1],d=c.indexOf("?");return d!=-1?c.substring(0,d):c}function r(a){var b;if(typeof a=="object")for(var c in a)a[c]&&(b={name:c,url:a[c]});else b={name:q(a),url:a};var d=h[b.name];if(d&&d.url===b.url)return d;h[b.name]=b;return b}function s(a,b){if(a){typeof a=="object"&&(a=[].slice.call(a));for(var c=0;c<a.length;c++)b.call(a,a[c],c)}}function t(a){return Object.prototype.toString.call(a)=="[object Function]"}function u(a){a=a||h;var b=false,c=0;for(var d in a){if(a[d].state!=o)return false;b=true,c++}return b||c===0}function v(a){a.state=l,s(a.onpreload,function(a){a.call()})}function w(a,b){a.state||(a.state=m,a.onpreload=[],y({src:a.url,type:"cache"},function(){v(a)}))}function x(a,b){if(a.state==o&&b)return b();if(a.state==n)return k.ready(a.name,b);if(a.state==m)return a.onpreload.push(function(){x(a,b)});a.state=n,y(a.url,function(){a.state=o,b&&b(),s(g[a.name],function(a){p(a)}),d&&u()&&s(g.ALL,function(a){p(a)})})}function y(c,d){var e=a.createElement("script");e.type="text/"+(c.type||"javascript"),e.src=c.src||c,e.async=false,e.onreadystatechange=e.onload=function(){var a=e.readyState;!d.done&&(!a||/loaded|complete/.test(a))&&(d(),d.done=true)},b.appendChild(e)}setTimeout(function(){c=true,s(f,function(a){a()})},0);function z(){d||(d=true,s(e,function(a){p(a)}))}window.addEventListener?(a.addEventListener("DOMContentLoaded",z,false),window.addEventListener("onload",z,false)):window.attachEvent&&(a.attachEvent("onreadystatechange",function(){a.readyState==="complete"&&z()}),window.frameElement==null&&b.doScroll&&function(){try{b.doScroll("left"),z()}catch(a){setTimeout(arguments.callee,1);return}}(),window.attachEvent("onload",z)),!a.readyState&&a.addEventListener&&(a.readyState="loading",a.addEventListener("DOMContentLoaded",handler=function(){a.removeEventListener("DOMContentLoaded",handler,false),a.readyState="complete"},false))})(document)
-->
</script>


<script type="text/javascript" src="{jquery_js}"></script>
<script type="text/javascript" src="{jquery_ui_js}"></script>
<script type="text/javascript" src="{jquery_validate_js}"></script>
<script type="text/javascript" src="{swfobject_js}"></script>

<script type="text/javascript" src="/js/base/jquery.indent-1.0.min.js"></script>
<script type="text/javascript" src="/js/base/jquery-wet.js"></script>

{extra}

 </head>
<body>
<div class="aelua_body">
{bar}
]])
	
	return replace(p,d)

end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
footer=function(d)

	local cache=require("wetgenes.aelua.cache")
	local data=require("wetgenes.aelua.data")
	local fetch=require("wetgenes.aelua.fetch")

	d.bar=""
	if opts_html.bar=="foot" then
		d.bar=get_html("aelua_bar",d)
	end
	
	if not d.time then
		d.time=math.ceil((os.clock()-d.srv.clock)*1000)/1000
	end
	
	if not d.api_time then
		d.api_time=math.ceil( (cache.api_time + data.api_time + fetch.api_time)*1000 )/1000
	end
	
	local mods=""
	
	if d.mod_name and d.mod_link then
	
		mods=" mod <a href=\""..d.mod_link.."\">"..d.mod_name.."</a>"
	
	elseif d.app_name and d.app_link then
	
		mods=" app <a href=\""..d.app_link.."\">"..d.app_name.."</a>"
		
	end
	
	d.about=d.about or about(d)

	d.report=d.report or "Page generated by <a href=\"http://code.google.com/p/aelua/\">aelua</a>"..mods.." in "..(d.time or 0).."("..(d.api_time or 0)..") seconds with "..((fetch.count or 0)+(data.count or 0)).." queries and "..(cache.count_got or 0).."/"..(cache.count or 0).." caches."
		
	local p=get_plate("footer",
[[
</div>
<div class="aelua_footer">
{about}
{report}
{bar}
</div>
</body>
</html>
]])
	return replace(p,d)

end
		
-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
about=function(d)

	d=d or {}
	d.bootstrapp="<a href=\"http://boot-str.appspot.com/\">bootstrapp</a>"
	d.mods="<a href=\"http://boot-str.appspot.com/about\">mods</a>"
	d.aelua="<a href=\"http://code.google.com/p/aelua/\">aelua</a>"
	d.wetgenes="<a href=\"http://about.wetgenes.com\">wetgenes</a>"
	
--	d.version=opts.bootstrapp_version or 0
--	d.lua="<a href=\"http://www.lua.org/\">lua</a>"
--	d.appengine="<a href=\"http://code.google.com/appengine/\">appengine</a>"

	local p=get_plate("about",[[
<div class="aelua_about">
	{bootstrapp} is a distribution of {aelua} {mods} developed by {wetgenes}.
</div>
]])
	return replace(p,d)

end

-----------------------------------------------------------------------------
--
-- both bars simply joined
--
-----------------------------------------------------------------------------
aelua_bar=function(d)
	return home_bar(d)..user_bar(d)
end
	
-----------------------------------------------------------------------------
--
-- a home / tabs / next page area
--
-----------------------------------------------------------------------------
home_bar=function(d)

	local crumbs=d.crumbs or d.srv.crumbs
	local s
	for i=1,#crumbs do local v=crumbs[i]
		if v.text then
			if not s then s="" else s=s.." / " end
			s=s.."<a href=\""..v.url.."\">"..v.text.."</a>"
		end
	end
	d.crumbs=s or "<a href=\"/\">Home</a>" -- default
		
	local p=get_plate("home_bar",[[
<div class="aelua_bar">
<div class="aelua_home_bar">
{crumbs}
</div>
]])
	return replace(p,d)

end

		
-----------------------------------------------------------------------------
--
-- a hello / login / logout area
--
-----------------------------------------------------------------------------
user_bar=function(d)

	d.adminbar=d.adminbar or ""
	d.alerts_html=d.alerts_html or (d.srv and d.srv.alerts_html) or ""

	local user=d.srv and d.srv.user
	local hash=d.srv and d.srv.sess and d.srv.sess.key and d.srv.sess.key.id
	
	if user then
	
		d.name="<a href=\"/profile/"..user.cache.id.."\" >"..(user.cache.name or "?").."</a>"
	
		d.hello="Hello, "..d.name.."."
		
		d.action="<a href=\"/dumid/logout/"..hash.."/?continue="..url_esc(d.srv.url).."\">Logout?</a>"
		d.js=""
	else
		d.hello="Hello, Anon."
		d.action="<a href=\"/dumid/login/?continue="..url_esc(d.srv.url).."\">Login?</a>"
--		d.action="<a href=\"#\" onclick=\"return dumid_show_login_popup();\">Login?</a>"
	
	end
	
--[[
<script language="javascript" type="text/javascript">
function dumid_show_login_popup()
{
$("body").prepend("<iframe style='position:absolute;left:50%;top:50%;margin-left:-200px;margin-top:-150px;width:400px;height:300px' src='/dumid/login/?continue=..url_esc(d.srv.url)..'></iframe>");
return false;		
}
</script>
]]
	local p=get_plate("user_bar",[[
<div class="aelua_user_bar">
{hello} {action}
</div>

<div class="aelua_clear"> </div>
</div>
{adminbar}
{alerts_html}
]])
	return replace(p,d)

end

-----------------------------------------------------------------------------
--
-- missing content
--
-----------------------------------------------------------------------------
missing_content=function(d)

	local p=get_plate("missing_content",[[
MISSING CONTENT<br/>
<br/>
<a href="/">return to the homepage?</a><br/>
]])
	return replace(p,d)

end


-----------------------------------------------------------------------------
--
-- load default plates from disk or cache
-- and import default helper functions into the given environment tab
-- call this at the top of your main html module with _M as the argument
--
-----------------------------------------------------------------------------

function import(tab)

	tab.plates=tab.plates or {}

	local text=sys.bytes_to_string(sys.file_read("lua/plates.html"))
	local chunks=waka.text_to_chunks(text)
	
	for i=1,#chunks do local v=chunks[i] -- copy into plates lookup
		tab.plates[v.name]=v.text
	end
	
	function get_html(n,d)
		return ( tab[n](d) )
	end
	function get_plate(name,alt)
		return ( tab.plates[name] or alt or name )
	end
	get_plate_orig=get_plate
	function get_plate(name,alt) -- some simple debug
		return "\n<!-- #"..name.." -->\n\n"..get_plate_orig(name,alt)
	end
	
-- build default plates functions for all plates that we found
	for n,_ in pairs(tab.plates) do

		local f=function(name)
			return function(d)
				return replace(get_plate(name),d)
			end
		end
		
		if not tab[n] then -- create function
			tab[n]=f(n)
		end

	end

-- copy our functions 
	for _,n in ipairs{
						"get_plate_orig",
						"get_plate",
						"rough_english_duration",
						"num_to_thousands",
						"header",
						"footer",
						"about",
						"aelua_bar",
						"home_bar",
						"user_bar",
						"missing_content",
					} do
		tab[n]=_M[n]
	end
		


end



