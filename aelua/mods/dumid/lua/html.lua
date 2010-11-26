
local sys=require("wetgenes.aelua.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("html")

local setmetatable=setmetatable

module("dumid.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 



-----------------------------------------------------------------------------
--
-- special popup header
--
-----------------------------------------------------------------------------
dumid_header=function(d)

	d.title=d.title or "Choose your dum id!"
	
	d.jquery_js="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
		
	if d.srv.url_slash[3]=="host.local:8080" then -- a local shop only servs local people
		d.jquery_js="/js/jquery-1.4.2.min.js"
	end

	return replace([[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
 <head>
<title>{title}</title>

<link REL="SHORTCUT ICON" HREF="/favicon.ico">
<link rel="stylesheet" type="text/css" href="/css/dumid/popup.css" /> 
<script type="text/javascript" src="{jquery_js}"></script>

 </head>
<body>
<div class="popup">
	
]],d)

end


-----------------------------------------------------------------------------
--
-- special popup footer
--
-----------------------------------------------------------------------------
dumid_footer=function(d)
	
	return replace([[

	<div class="footer">
		<div class="foot">
			This is a <a href="http://dum-id.appspot.com/">dumid</a> login system.
		</div>
	</div>
</div>
<br/>
<div class="popupwet">
	<div class="head">Hello, shi :)</div> 
	<div class="from">hoe-house.appspot.com</div> 
	<div class="wants">wants to know your</div> 
	<div class="data">name</div> 
	<div class="buttons"> 
		<a class="allow" href="http://hoe-house.appspot.com/dumid/callback/wetgenes/?continue=http://hoe-house.appspot.com/&confirm=35f27efc5473cf81b75dc3392a58c9d0" target="_parent">Confirm</a> 
		<a class="deny" href="http://hoe-house.appspot.com/dumid/callback/wetgenes/?continue=http://hoe-house.appspot.com/&deny=0" target="_parent">Deny</a> 
	</div>
	<div class="footer">
		<div class="foot">
			This is a <a href="http://dum-id.appspot.com/">dumid</a> login system.
		</div>
	</div>
</div>


</body>
</html>
]],d)

end


-----------------------------------------------------------------------------
--
-- special popup footer
--
-----------------------------------------------------------------------------
dumid_choose=function(d)
	
	d.continue=url_esc(d.continue)
	return replace([[
<div class="contop">
	Login with
</div>
<div class="cont">
	<a class="button" href="{srv.url_base}login/wetgenes/?continue={continue}">WetGenes</a>
</div>
<div class="cont">
	<a class="button" href="{srv.url_base}login/google/?continue={continue}">Google</a>
</div>
<div class="cont">
	<a class="button" href="{srv.url_base}login/twitter/?continue={continue}">Twitter</a>
</div>
]],d)

end

