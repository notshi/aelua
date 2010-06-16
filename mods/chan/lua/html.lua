

local sys=require("wetgenes.aelua.sys")
local user=require("wetgenes.aelua.user")

local f=require("wetgenes.html")

local html_base=require("html_base")

local setmetatable=setmetatable

module("chan.html")

setmetatable(_M,{__index=html_base}) -- use a meta table to also return html_base 



-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
chan_form=function(d)

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
chan_post=function(d)

	d.img=d.img or ""
	
	if d.post.cache.image and d.post.cache.image~=0 then
	
		d.img="<a href=\"/chan/image/"..d.post.cache.image..".png\" ><img src=\"/chan/thumb/"..d.post.cache.image..".png\" /></a>"
	
	end

	return f.replace([[
	
<div>

EMAIL:{post.cache.email}<br/>
SUBJECT:{post.cache.subject}<br/>
BODY:{post.cache.body}<br/>
IMG:{img}<br/>

</div>

]],d)

end
			
			
			


