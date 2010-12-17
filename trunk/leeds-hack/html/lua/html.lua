

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
local tostring=tostring

module("html")

-----------------------------------------------------------------------------
--
-- load and parse plates.html
--
-----------------------------------------------------------------------------
plates={}

do
	local text=sys.bytes_to_string(sys.file_read("lua/plates.html"))
	local chunks=waka.text_to_chunks(text)
	
	for i=1,#chunks do local v=chunks[i] -- copy into plates lookup
		plates[v.name]=v.text
	end
end
function get_plate(name)
	return ( plates[name] or name )
end
local get_plate_orig=get_plate

local function get_plate(name) -- some simple debug
	return "\n<!-- #"..name.." -->\n\n"..get_plate_orig(name)
end

-- build default plates functions for all plates
for n,v in pairs(plates) do

	local f=function(name)
		return function(d)
			return replace(get_plate_orig(name),d)
		end
	end
	
	if not _M[n] then
		_M[n]=f(n)
	end

end

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
	d.extra=""
	
	if d.css then --embed some css
		d.extra=d.extra.."<style type=\"text/css\">"..d.css.."</style>"
		
--		d.extra=d.extra.."<link rel=\"stylesheet\" type=\"text/css\" href=\""..d.css.."\">"
	end
	
	d.jquery_js="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
	d.jquery_ui_js="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.2/jquery-ui.min.js"
	d.swfobject_js="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"
	d.jquery_validate_js="http://ajax.microsoft.com/ajax/jQuery.Validate/1.6/jQuery.Validate.min.js"
	
	if d.srv.url_slash[3]=="host.local:8080" then -- a local shop only servs local people
		d.jquery_js="/js/jquery-1.4.2.js"
		d.jquery_ui_js="/js/jquery-ui-1.8.2.custom.min.js"
		d.swfobject_js="/js/swfobject.js"
		d.jquery_validate_js="/js/jquery.validate.js"
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

	return replace(get_plate_orig("header"),d)

end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
footer=function(d)

	if not d.time then
		d.time=math.ceil((os.clock()-d.srv.clock)*1000)/1000
	end
	
	local mods=""
	
	if d.mod_name and d.mod_link then
	
		mods=" mod <a href=\""..d.mod_link.."\">"..d.mod_name.."</a>"
	
	elseif d.app_name and d.app_link then
	
		mods=" app <a href=\""..d.app_link.."\">"..d.app_name.."</a>"
		
	end

	d.report="Generated by <a href=\"http://code.google.com/p/aelua/\">aelua</a>"..mods.." in "..(d.time or 0).." Seconds."
		
	return replace(get_plate("footer"),d)

end
		
-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
about=function(d)

	d=d or {}
	d.hoehouse="<a href=\"http://hoe-house.appspot.com/\">hoe house</a>"
	d.whorehouse="<a href=\"http://whorehouse.naken.cc/\">whore house</a>"
	d.aelua="<a href=\"http://code.google.com/p/aelua/\">aelua</a>"
	d.lua="<a href=\"http://www.lua.org/\">lua</a>"
	d.appengine="<a href=\"http://code.google.com/appengine/\">appengine</a>"
	d.wetgenes="<a href=\"http://www.wetgenes.com/\">wetgenes</a>"

	return replace(get_plate("about"),d)

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
		
	return replace(get_plate("home_bar"),d)

end

-----------------------------------------------------------------------------
--
-- a hello / login / logout area
--
-----------------------------------------------------------------------------
user_bar=function(d)

	local user=d.H and d.H.user
	local hash=d.H and d.H.sess and d.H.sess.key and d.H.sess.key.id
	if user then
	
		d.name="<span title=\""..user.cache.email.."\" >"..(user.cache.name or "?").."</span>"
	
		d.hello="Hello, "..d.name.."."
		
--		d.action="<div class=\"log3\"><div class=\"logit\"><a href=\""..users.logout_url(d.srv.url).."\">Logout?</a></div></div>"
		d.action="<div class=\"log3\"><div class=\"logit\"><a href=\"/dumid/logout/"..hash.."/?continue="..url_esc(d.srv.url).."\">Logout?</a></div></div>"
	else
		d.hello="Hello, Anon."
--		d.action="<div class=\"log2\"><div class=\"logit\"><a href=\""..users.login_url(d.srv.url).."\">Login?</a></div></div>"
		d.action="<div class=\"log2\"><div class=\"logit\"><a href=\"/dumid/login/?continue="..url_esc(d.srv.url).."\">Login?</a></div></div>"
	
	end
	
	return replace(get_plate("user_bar"),d)

end

-----------------------------------------------------------------------------
--
-- suggest an act
--
-----------------------------------------------------------------------------
request_login=function(d)

	d.action="<a href=\"/dumid/login/?continue="..url_esc(d.srv.url).."\">Login</a>"
	
	return replace(get_plate("request_login"),d)

end

-----------------------------------------------------------------------------
--
-- suggest an action
--
-----------------------------------------------------------------------------
request_join=function(d)

	d.action="<a href=\""..d.H.url_base.."do/"..d.act.."\">Join</a>"
	
	return replace(get_plate("request_join"),d)

end

-----------------------------------------------------------------------------
--
-- missing content
--
-----------------------------------------------------------------------------
missing_content=function(d)

	return replace(get_plate("missing_content"),d)

end
