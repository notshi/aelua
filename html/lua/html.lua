
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
--
-----------------------------------------------------------------------------
html.chan_form=function(d)

		
	return f.replace([[
	
<form name="chanpost" id="chanpost" action="/chan/post" method="post" enctype="multipart/form-data">

	<input type="hidden" name="parent" value="0">

	<input type="text" name="subject" size="40" maxlength="75" accesskey="s">

	<input type="submit" value="Submit" accesskey="z"> <br/>

	<textarea name="message" cols="48" rows="4" accesskey="m"></textarea> <br/>

	<input type="file" name="file" size="35" accesskey="f"> 

</form>

]],d)

end
			
			
			
		