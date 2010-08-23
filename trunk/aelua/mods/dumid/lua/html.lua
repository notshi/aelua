
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
  <div class="foot">This is a <a href="http://dum-id.appspot.com/">dumid</a> login system.</div>
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
<div>
Login with<br/><br/> <a class="button" href="{srv.url_base}login/wetgenes/?continue={continue}">your wetgenes account</a> or <br/>
<br/> <a class="button" href="{srv.url_base}login/google/?continue={continue}">your google account</a> or <br/>
<br/> <a class="button" href="{srv.url_base}login/twitter/?continue={continue}">your twitter account</a> <br/>
</div>
]],d)

end

