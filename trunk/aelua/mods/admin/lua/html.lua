
local sys=require("wetgenes.aelua.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local wet_string=require("wetgenes.string")

local html=require("html")

local setmetatable=setmetatable
local opts=opts

module("admin.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 


-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="admin"
	d.mod_link="http://boot-str.appspot.com/about/mod/admin"
	return html.footer(d)
end

-----------------------------------------------------------------------------
--
-- edit
--
-----------------------------------------------------------------------------
admin_edit=function(d)
	
	d=d or {}
	d.bootstrapp="<a href=\"http://boot-str.appspot.com/\">bootstrapp</a>"	
	d.version=opts.bootstrapp_version or 0
	d.oldopts=wet_string.serialize(opts,{pretty=true})

	return replace([[
<div>
<p>This install is running {bootstrapp} version {version}</p>
<p>Visit <a href="http://www.wetgenes.com/bootstrapp.php">http://www.wetgenes.com/bootstrapp.php</a> to upgrade (relax all your site data will remain).</p>
<p> <a href="/admin/console">console</a> <a href="/data">data</a> <a href="/blog//admin">blog</a> <a href="/blog//note">note</a> </p>
<form name="post" id="post" action="" method="post" enctype="multipart/form-data">
	<textarea name="text" cols="120" rows="24" class="field" >{text}</textarea>
	<br/>
	<input type="submit" name="submit" value="Save" class="button" />
	<br/>	
	<br/>	
</form>
<p>These are your current opts, anything typed in above will modify or replace them.</p>
<pre>{oldopts}</pre>
</div>
]],d)

end

