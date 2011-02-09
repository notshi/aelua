
local sys=require("wetgenes.aelua.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc
local html_esc=wet_html.esc

local html=require("html")

local setmetatable=setmetatable

local os=require("os")
local string=require("string")

module("blog.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 






-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="blog"
	d.mod_link="http://boot-str.appspot.com/about/mod/blog"
	return html.footer(d)
end


-----------------------------------------------------------------------------
--
-- edit form
--
-----------------------------------------------------------------------------
blog_edit_form=function(d)

	d.text=html_esc(d.it.text)

	return replace([[
<form name="post" id="post" action="" method="post" enctype="multipart/form-data">
	<table style="float:right">
	<tr><td> group   </td><td> <input type="text" name="group"   size="20" value="{it.group}"  /> </td></tr>
	<tr><td> pubname </td><td> <input type="text" name="pubname" size="20" value="{it.pubname}"/> </td></tr>
	<tr><td> layer   </td><td> <input type="text" name="layer"   size="20" value="{it.layer}"  /> </td></tr>
	</table>
	<textarea style="width:100%" name="text" cols="80" rows="24" class="field" >{text}</textarea>
	<br/>
	<input type="submit" name="submit" value="Save" class="button" />
	<input type="submit" name="submit" value="Preview" class="button" />
	<input type="submit" name="submit" value="{publish}" class="button" />
	<br/>	
</form>
<script type="text/javascript">
	$(function(){
		$('textarea[name=text]').indent();
	});
</script>
]],d)

end

-----------------------------------------------------------------------------
--
-- a tool bar only admins get to see
--
-----------------------------------------------------------------------------
blog_admin_links=function(d)

	if not ( d and d.user and d.user.cache and d.user.cache.admin ) then return "" end
	
	if d.it then
		d.edit_post=replace([[<a href="{srv.url_base}/admin/edit/$hash/{it.id}" class="button" > Edit Post </a>]],d)
	else
		d.edit_post=""
	end
	return replace([[
	<div class="aelua_admin_bar">
		<a href="{srv.url_base}" class="button" > View Blog </a> 
		<a href="{srv.url_base}/admin/pages" class="button" > List </a> 
		<a href="{srv.url_base}/admin/edit/$newpage" class="button" > New Post </a>
		{edit_post}
	</div>
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


-----------------------------------------------------------------------------
--
-- atom wrappers
--
-----------------------------------------------------------------------------
blog_atom_head=function(d)
	return replace([[<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">

	<title>{title}</title>
	<link rel="self" href="{srv.url_base}.atom"/>
	<updated>{updated}</updated>
	<author>
		<name>{author_name}</name>
	</author>
	<id>{srv.url_base}.atom</id>
]],d)

end

blog_atom_foot=function(d)
	return replace([[</feed>
]],d)

end
blog_atom_item=function(d)
	d.pubdate=(os.date("%Y-%m-%dT%H:%M:%SZ",d.it.pubdate))
	d.link=d.srv.url_base..d.it.pubname:sub(2)
	d.id=d.link
	return replace([[
	<entry>
		<title type="text">{refined.title}</title>
		<link href="{link}"/>
		<id>{id}</id>
		<updated>{pubdate}</updated>
		<content type="html">{text}</content>
	</entry>
]],d)

end

