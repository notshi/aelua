
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

	local user=d.srv.user
	local hash=d.srv.sess and d.srv.sess.key and d.srv.sess.key.id
	if user then
	
		d.name="<span title=\""..user.cache.email.."\" >"..(user.cache.name or "?").."</span>"
	
		d.hello="Hello, "..d.name.."."
		
		d.action="<a href=\"/dumid/logout/"..hash.."/?continue="..url_esc(d.srv.url).."\">Logout?</a>"
	else
		d.hello="Hello, Anon."
		d.action="<a href=\"/dumid/login/?continue="..url_esc(d.srv.url).."\">Login?</a>"
	
	end
	
	if user and user.cache and user.cache.admin then -- admin
		d.admin=replace([[
	<div style="float:right">
		<form action="" method="POST" enctype="multipart/form-data">
			<button type="submit" name="edit" class="button" >Edit</button>
		</form>
	</div>
]],d)
	end
	
	return replace([[
<div style="display:relative">
<div style="float:left">
{crumbs}
</div>
<div style="float:right">
{hello} {action}
</div>
{admin}
<div style="clear:both"></div>
</div>
]],d)

end
