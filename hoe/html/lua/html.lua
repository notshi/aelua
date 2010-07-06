

local os=os
local users=require("wetgenes.aelua.users")

local wet_html=require("wetgenes.html")

local string=string
local math=math

module("html")

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
header=function(d)

	
	if not d.title then
		local crumbs=d.srv.crumbs
		local s
		for i=1,#crumbs do local v=crumbs[i]
			if not s then s="" else s=s.." - " end
			s=s..v.title
		end
		d.title=s
	end

	return wet_html.replace([[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
 <head>
<title>{title}</title>

<link REL="SHORTCUT ICON" HREF="/favicon.ico">

<link rel="stylesheet" type="text/css" href="/css/jnice.css" /> 
<link rel="stylesheet" type="text/css" href="/css/aelua.css" /> 

<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/js/jquery.jnice.js"></script>


 </head>
<body>
<div class="aelua_base">
]],d)

end

-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
footer=function(d)

	if not d.time then
		d.time=math.ceil((os.clock()-d.srv.clock)*1000)/1000
	end
	
	local mods=""
	
	if d.mod_name and d.mod_link then
	
		mods=" mod <a href=\""..d.mod_link.."\">"..d.mod_name.."</a>"
	
	end

	d.report="Generated by <a href=\"http://code.google.com/p/aelua/\">aelua</a>"..mods.." in "..(d.time or 0).." Seconds."
		
	return wet_html.replace([[
<div class="aelua_foot_data">
<br/>
<br/>
<br/>
{report}<br/>
<br/>
</div>
</div>
</body>
</html>
]],d)

end
		
-----------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------
about=function(d)

	d=d or {}
	d.hoehouse="<a href=\"http://hoe-house.appspot.com/\">hoe house</a>"
	d.whorehouse="<a href=\"http://whorehouse.naken.cc/\">whore house</a>"
	d.aelua="<a href=\"http://code.google.com/p/aelua/\">aelua</a>"
	d.lua="<a href=\"http://www.lua.org/\">lua</a>"
	d.appengine="<a href=\"http://code.google.com/appengine/\">appengine</a>"
	d.wetgenes="<a href=\"http://www.wetgenes.com/\">wetgenes</a>"

	return wet_html.replace([[
<div class="aelua_about">
<br/>
<br/>
{hoehouse} is a friendly hommage to {whorehouse}.<br/>
{hoehouse} is an example {aelua} app.<br/>
<br/>
{aelua} is a {lua} core and framework compatibile with {appengine}.<br/>
{aelua} and {hoehouse} are designed and developed by {wetgenes}.<br/>
</div>
]],d)

end

		
-----------------------------------------------------------------------------
--
-- a home / tabs / next page area
--
-----------------------------------------------------------------------------
home_bar=function(d)

	local crumbs=d.srv.crumbs
	local s
	for i=1,#crumbs do local v=crumbs[i]
		if not s then s="" else s=s.." / " end
		s=s.."<a href=\""..v.url.."\">"..v.link.."</a>"
	end
	d.crumbs=s
		
	return wet_html.replace([[
	
<div class="aelua_home_bar">
{crumbs}
</div>

]],d)

end

		
-----------------------------------------------------------------------------
--
-- a hello / login / logout area
--
-----------------------------------------------------------------------------
user_bar=function(d)

	if d.user then
	
		d.name="<span title=\""..d.user.cache.email.."\" >"..(d.user.cache.name or "?").."</span>"
	
		d.hello="Hello "..d.name.."."
		
		d.action="<a href=\""..users.logout_url(d.srv.url).."\">Logout?</a>"
	else
		d.hello="Hello Anon."
		d.action="<a href=\""..users.login_url(d.srv.url).."\">Login?</a>"
	
	end
	
	return wet_html.replace([[
	
<div class="aelua_user_bar">
{hello}
{action}
</div>

]],d)

end

-----------------------------------------------------------------------------
--
-- a basic player area for the viewer
--
-----------------------------------------------------------------------------
player_bar=function(d)

	if d.player then
			
		return wet_html.replace([[	
<div class="hoe_player_bar">
<span class="hoe_player_bar_energy">energy={player.energy}</span>
<span class="hoe_player_bar_score">score={player.score}</span>
<span class="hoe_player_bar_bux">bux={player.bux}</span>
<span class="hoe_player_bar_hoes">hoes={player.hoes}</span>
<span class="hoe_player_bar_houses">houses={player.houses}</span>
<span class="hoe_player_bar_scarecrows">scarecrows={player.scarecrows}</span>
</div>
]],d)

	end
	
	return wet_html.replace([[	
<div class="hoe_player_bar">
</div>
]],d)

end

-----------------------------------------------------------------------------
--
-- display a player row
--
-----------------------------------------------------------------------------
player_row=function(d)

	if d.player then
			
		return wet_html.replace([[	
<div class="hoe_player_row">
<span class="hoe_player_row_name">{player.name}</span>
<span class="hoe_player_row_score">score={player.score}</span>
<span class="hoe_player_row_bux">bux={player.bux}</span>
<span class="hoe_player_row_hoes">hoes={player.hoes}</span>
<span class="hoe_player_row_houses">houses={player.houses}</span>
<span class="hoe_player_row_scarecrows">scarecrows={player.scarecrows}</span>
<span class="hoe_player_row_shout">{player.shout}</span>
</div>
]],d)

	end
	
	return wet_html.replace([[	
<div class="hoe_player_row">
</div>
]],d)

end

-----------------------------------------------------------------------------
--
-- display most player info on thier profile
--
-----------------------------------------------------------------------------
player_base=function(d)

	if d.player then
			
		return wet_html.replace([[	
<div class="hoe_player_base">
<span class="hoe_player_base_name">{player.name}</span>
<span class="hoe_player_base_score">score={player.score}</span>
<span class="hoe_player_base_bux">bux={player.bux}</span>
<span class="hoe_player_base_hoes">hoes={player.hoes}</span>
<span class="hoe_player_base_houses">houses={player.houses}</span>
<span class="hoe_player_base_scarecrows">scarecrows={player.scarecrows}</span>
<span class="hoe_player_base_shout">{player.shout}</span>
</div>
]],d)

	end
	
	return wet_html.replace([[	
<div class="hoe_player_base">
</div>
]],d)

end
			
-----------------------------------------------------------------------------
--
-- sugest an act
--
-----------------------------------------------------------------------------
request_login=function(d)

	d.action="<a href=\""..users.login_url(d.srv.url).."\">Login</a>"
	
	return wet_html.replace([[
	
<div class="hoe_acts">
Please {action} if you wish to join this game.
</div>

]],d)

end

-----------------------------------------------------------------------------
--
-- sugest an action
--
-----------------------------------------------------------------------------
request_join=function(d)

	d.action="<a href=\""..d.H.url_base.."do/"..d.act.."\">Join</a>"
	
	return wet_html.replace([[
	
<div class="hoe_acts">
Click {action} to {action} this game.
</div>

]],d)

end

			
			
		
			
		
