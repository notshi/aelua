
local sys=require("wetgenes.aelua.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("html")

local setmetatable=setmetatable

local os=require("os")
local string=require("string")

module("data.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 






-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="data"
	d.mod_link="http://boot-str.appspot.com/about/mod/data"
	return html.footer(d)
end


-----------------------------------------------------------------------------
--
-- data form
--
-----------------------------------------------------------------------------
data_upload_form=function(d)

	return replace([[
<form name="post" id="post" action="" method="post" enctype="multipart/form-data">

	id : <input type="text" name="dataid"   size="40" value="0"  /> <br />
	filename : <input type="text" name="filename"   size="40" value=""  /> <br />
	mimetype : <input type="text" name="mimetype"   size="40" value=""  /> <br />
	upload : <input type="file" name="filedata" size="40" />  <br />
	<input type="submit" name="submit" value="Upload" class="button" /> <br />

</form>
]],d)

end


-----------------------------------------------------------------------------
--
-- data info
--
-----------------------------------------------------------------------------
data_list_item=function(d)

	return replace([[
<div>
<a href="/data//edit{it.cache.pubname}" >edit</a> <a href="/data{it.cache.pubname}"> <img src="/data{it.cache.pubname}" style="max-width:100px;max-height:100px" />{it.cache.pubname}</a>
</div>
]],d)

end
