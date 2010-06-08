
-- create a global table for keeping templates in
html=html or {}



local f=require("wetgenes.html")


	
-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
html.chan_form=function(d)

	if not d.parent then d.parent="" end
		
	return f.replace([[
	
<form name="chanpost" id="chanpost" action="/chan/post" method="post" enctype="multipart/form-data">

	<input type="hidden" name="parent" value="{parent}">

	<input type="text" name="subject" size="40" maxlength="75" accesskey="s"> <br/>

	<textarea name="message" cols="48" rows="4" accesskey="m"></textarea> <br/>

	<input type="file" name="file" size="35" accesskey="f"> 

	<input type="submit" value="Post" accesskey="z"> <br/>
	
</form>

]],d)

end
			
-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
html.chan_post=function(d)

	return f.replace([[
	
<div>

EMAIL:{post.cache.email}<br/>
SUBJECT:{post.cache.subject}<br/>
BODY:{post.cache.body}<br/>

</div>

]],d)

end
			
			
			


module("chan.html")

-- something of a dummy module. the data is set in the global html table



