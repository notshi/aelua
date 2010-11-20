
local sys=require("wetgenes.aelua.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("html")

local setmetatable=setmetatable

module("waka.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 






-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="waka"
	d.mod_link="http://code.google.com/p/aelua/wiki/ModWaka"
	return html.footer(d)
end


-----------------------------------------------------------------------------
--
-- control bar
--
-----------------------------------------------------------------------------
waka_bar=function(d)


	local s1=home_bar(d)
	local s2=user_bar(d)


	d.admin=""
	if d.srv and d.srv.user and d.srv.user.cache and d.srv.user.cache.admin then -- admin
		d.admin=replace([[
	<div style="float:right">
		<form action="" method="POST" enctype="multipart/form-data">
			<button type="submit" name="submit" value="edit" class="button" >Edit</button>
		</form>
	</div>
]],d)
	end
	
	return replace(s1..s2..d.admin)

end

-----------------------------------------------------------------------------
--
-- edit form
--
-----------------------------------------------------------------------------
waka_edit_form=function(d)

	return replace([[
<form name="post" id="post" action="" method="post" enctype="multipart/form-data">
	<textarea name="text" cols="120" rows="24" class="field" >{text}</textarea>
	<br/>
	<input type="submit" name="submit" value="Save" class="button" />
	<input type="submit" name="submit" value="Preview" class="button" />
	<br/>	
</form>
]],d)

end
