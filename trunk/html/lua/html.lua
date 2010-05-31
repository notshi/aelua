
-- create a global table for keeping templates in
html=html or {}



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

<link rel="stylesheet" type="text/css" href="/css/base.css" /> 
<link rel="stylesheet" type="text/css" href="/css/links.css" /> 

<script type="text/javascript" src="/js/jquery.js"></script> 

 </head>
<body>
<div class="space_base">
]],d)

end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
html.footer=function(d)

	d.report="<br/><br/><br/>Output generated in "..(d.time or 0).." Seconds.<br/><br/>"
		
	return f.replace([[
</div>
<div class="space_foot_data">
{report}
</div>
</body>
</html>
]],d)

end
		
