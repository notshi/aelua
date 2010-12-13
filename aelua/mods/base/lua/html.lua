

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

	d.extra=(d.srv and d.srv.extra or "") .. ( d.extra or "" )
	
	for _,v in ipairs{d.srv or {},d} do
		
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
		if v.css then --embed some css
			d.extra=d.extra.."<style type=\"text/css\">"..v.css.."</style>"
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
	
	if not d.title then
		local crumbs=d.srv.crumbs
		local s
		for i=1,#crumbs do local v=crumbs[i]
			if not s then s="" else s=s.." - " end
			s=s..v.title
		end
		d.title=s
	end

	local p=get_plate_orig("header",
[[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head>

<title>{title}</title>

<link rel="alternate" type="application/atom+xml" title="blog Feed" href="/blog/.atom" />

<link rel="shortcut icon" href="/favicon.ico" />

<link rel="stylesheet" type="text/css" href="/css/base/aelua.css" /> 
<link rel="stylesheet" type="text/css" href="/wiki/.css" /> 

<script type="text/javascript" src="{jquery_js}"></script>
<script type="text/javascript" src="{jquery_ui_js}"></script>
<script type="text/javascript" src="{jquery_validate_js}"></script>
<script type="text/javascript" src="{swfobject_js}"></script>

<script type="text/javascript" src="/js/base/jquery-wet.js"></script>

{extra}

 </head>
<body>

<div class="aelua_body">
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

	if not d.time then
		d.time=math.ceil((os.clock()-d.srv.clock)*1000)/1000
	end
	
	local mods=""
	
	if d.mod_name and d.mod_link then
	
		mods=" mod <a href=\""..d.mod_link.."\">"..d.mod_name.."</a>"
	
	elseif d.app_name and d.app_link then
	
		mods=" app <a href=\""..d.app_link.."\">"..d.app_name.."</a>"
		
	end
	
	d.about=about(d)

	d.report="Page generated by <a href=\"http://code.google.com/p/aelua/\">aelua</a>"..mods.." in "..(d.time or 0).." seconds with "..(data.count or 0).." queries and "..(cache.count_got or 0).."/"..(cache.count or 0).." caches."
		
	local p=get_plate("footer",
[[
</div>
<div class="aelua_footer">
{about}
{report}
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
	d.aelua="<a href=\"http://code.google.com/p/aelua/\">aelua</a>"
	d.lua="<a href=\"http://www.lua.org/\">lua</a>"
	d.appengine="<a href=\"http://code.google.com/appengine/\">appengine</a>"
	d.wetgenes="<a href=\"http://www.wetgenes.com/\">wetgenes</a>"

	local p=get_plate("about",[[
<div class="aelua_about">
	{aelua} is a {lua} core and framework compatible with {appengine}.<br/>
	{aelua} is designed and developed by {wetgenes}.<br/>
</div>
]])
	return replace(p,d)

end

		
-----------------------------------------------------------------------------
--
-- a home / tabs / next page area
--
-----------------------------------------------------------------------------
home_bar=function(d)

	local crumbs=d.srv.crumbs
	local s
	for i=1,#crumbs do local v=crumbs[i]
		if not s then s="" else s=s.." / " end
		s=s.."<a href=\""..v.url.."\">"..v.link.."</a>"
	end
	d.crumbs=s or "<a href=\"/\">Home</a>"
		
	local p=get_plate("home_bar",[[
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

	local user=d.srv and d.srv.user
	local hash=d.srv and d.srv.sess and d.srv.sess.key and d.srv.sess.key.id
	
	if user then
	
		d.name="<span title=\""..user.cache.email.."\" >"..(user.cache.name or "?").."</span>"
	
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
						"home_bar",
						"user_bar",
						"missing_content",
					} do
		tab[n]=_M[n]
	end
		


end



