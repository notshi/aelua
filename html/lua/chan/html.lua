
-- create a global table for keeping templates in
html=html or {}



local f=require("wetgenes.html")


	
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
			
			
			

-- something of a dummy module. the html table squirting above is the most important part

module("chan.html")