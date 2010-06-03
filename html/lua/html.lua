
-- create a global table for keeping templates in
html=html or {}

local sys=require("wetgenes.aelua.sys")
local user=require("wetgenes.aelua.user")


local f=require("wetgenes.html")




-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
html.header=function(d)

	return f.replace([[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
 <head>
<title>{title}</title>

<link REL="SHORTCUT ICON" HREF="/favicon.ico">

<link rel="stylesheet" type="text/css" href="/css/aelua.css" /> 

<script type="text/javascript" src="/js/jquery.js"></script> 

 </head>
<body>
<div class="aelua_base">
]],d)

end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
html.footer=function(d)

	if not d.time then
		d.time=math.ceil((sys.clock()-d.srv.clock_start)*1000)/1000
	end

	d.report="<br/><br/><br/>Output generated in "..(d.time or 0).." Seconds.<br/><br/>"
		
	return f.replace([[
</div>
<div class="aelua_foot_data">
{report}
</div>
</body>
</html>
]],d)

end
		

		
-----------------------------------------------------------------------------
--
-- a home / tabs / next page area
--
-----------------------------------------------------------------------------
html.home_bar=function(d)

	d.home="<a href=\"/\">Home</a>"
		
	return f.replace([[
	
<div class="aelua_home_bar">
{home}
</div>

]],d)

end

		
-----------------------------------------------------------------------------
--
-- a hello / login / logout area
--
-----------------------------------------------------------------------------
html.user_bar=function(d)

	if user.user then
	
		d.name="<span title=\""..user.user.email.."\" >"..(user.user.name or "?").."</span>"
	
		d.hello="Hello "..d.name.."."
		
		d.action="<a href=\""..user.logout_url(d.srv.url).."\">Logout?</a>"
	else
		d.hello="Hello Anon."
		d.action="<a href=\""..user.login_url(d.srv.url).."\">Login?</a>"
	
	end
	
	return f.replace([[
	
<div class="aelua_user_bar">
{hello}
{action}
</div>

]],d)

end
			
			
			
		