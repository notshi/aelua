
local sys=require("wetgenes.aelua.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("html")

local setmetatable=setmetatable

module("blog.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 






-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="blog"
	d.mod_link="http://code.google.com/p/aelua/wiki/ModBlog"
	return html.footer(d)
end


-----------------------------------------------------------------------------
--
-- edit form
--
-----------------------------------------------------------------------------
blog_edit_form=function(d)

	return replace([[
<form name="post" id="post" action="" method="post" enctype="multipart/form-data">
	<table style="float:right">
	<tr><td> group   </td><td> <input type="text" name="group"   size="20" value="{it.group}"  /> </td></tr>
	<tr><td> pubname </td><td> <input type="text" name="pubname" size="20" value="{it.pubname}"/> </td></tr>
	<tr><td> layer   </td><td> <input type="text" name="layer"   size="20" value="{it.layer}"  /> </td></tr>
	</table>
	<textarea name="text" cols="120" rows="24" class="field" >{it.text}</textarea>
	<br/>
	<input type="submit" name="submit" value="Save" class="button" />
	<input type="submit" name="submit" value="Preview" class="button" />
	<br/>	
</form>
]],d)

end


-----------------------------------------------------------------------------
--
-- edit form
--
-----------------------------------------------------------------------------
blog_admin_head=function(d)
	return replace([[
<form>
]],d)
end

blog_admin_foot=function(d)
	return replace([[
</form>
]],d)
end

blog_admin_item=function(d)

	return replace([[
<div>
<input type="checkbox" name="{it.pubname}" value="Check"></input>
<a href="{srv.url_base}/admin/edit/$hash/{it.id}">
<span style="width:20px;display:inline-block;">{it.layer}</span>
<span style="width:200px;display:inline-block;">{it.pubname}</span>
<span style="width:400px;display:inline-block;">{chunks.title.text}</span>
{it.pubdate}
</a>
</div>
]],d)

end

