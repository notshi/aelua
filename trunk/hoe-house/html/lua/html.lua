

local users=require("wetgenes.aelua.users")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local table=table
local string=string
local math=math
local os=os

module("html")

function rough_english_duration(t)
	t=math.floor(t)
	if t>=2*12*4*7*24*60*60 then
		return math.floor(t/(12*4*7*24*60*60)).." years"
	elseif t>=2*4*7*24*60*60 then
		return math.floor(t/(4*7*24*60*60)).." months"
	elseif t>=2*7*24*60*60 then
		return math.floor(t/(7*24*60*60)).." weeks"
	elseif t>=2*24*60*60 then
		return math.floor(t/(24*60*60)).." days"
	elseif t>=2*60*60 then
		return math.floor(t/(60*60)).." hours"
	elseif t>=2*60 then
		return math.floor(t/(60)).." minutes"
	elseif t>=2 then
		return t.." seconds"
	elseif t==1 then
		return "1 second"
	else
		return "0 seconds"
	end
end

function num_to_thousands(n)
	local p=math.floor(n)
	if p<0 then p=-p end -- positive only
	local s=string.format("%d",p) -- force integer part only?
	local len=string.len(s)
	local skip=len%3 -- size of first batch
	local t={}
	if skip>0 then
		t[#t+1]=string.sub(s,1,skip)
	end
	for i=skip,len-3,3 do
		t[#t+1]=string.sub(s,i+1,i+3)
	end
	local s=table.concat(t,",")
	if n<0 then return "-"..s else return s end
end

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

	return replace([[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
 <head>
<title>{title}</title>

<link REL="SHORTCUT ICON" HREF="/favicon.ico">

<link rel="stylesheet" type="text/css" href="/css/jnice.css" /> 
<link rel="stylesheet" type="text/css" href="/css/hoe.css" /> 

<script type="text/javascript" src="/js/jquery.js"></script>
<script type="text/javascript" src="/js/jquery.jnice.js"></script>


 </head>
<body>
<div class="cont">
	<div class="header">
		<a href="/"><img src="/art/hoe.960x180.png" width="960" height="180"></a>
	</div>
	<div class="line"></div>
</div>

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
		
	return replace([[


<br/>
<br/>
<br/>
<div class="desc">{report}</div><br/>
<br/>
<br/>
<br/>


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

	return replace([[
<div class="chunk">
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
	d.crumbs=s or "<a href=\"/\">Home</a>"
		
	return replace([[
	
<div class="cont">
	<div class="chunk">
		<div class="chunk1">
			<div class="crum">
				<div class="crumit">{crumbs}</div>
			</div>
		</div>
		

]],d)

end

-----------------------------------------------------------------------------
--
-- a home / tabs / next page area
--
-----------------------------------------------------------------------------
hoe_menu_items=function(d)

		
	return replace([[
	

<div class="cont">
<div class="chunk3">
<div class="chunk3it">
Basic Menu
<div class="chunk3line"></div>
</div>
<div class="clear"></div>
</div>
<div class="menu">
<div class="menu1">
<div class="menuit"><a href="{H.url_base}work">WORK</a></div>
<div class="menuline"></div>
<div class="menup"><a href="{H.url_base}work"><img src="/art/worka.png" width="100" height="100"></a></div>
<div class="menun">Work to gain bux, hoes and bros.</div>
</div>
<div class="menu1">
<div class="menuit"><a href="{H.url_base}shop">SHOP</a></div>
<div class="menuline"></div>
<div class="menup"><a href="{H.url_base}shop"><img src="/art/shopa.png" width="100" height="100"></a></div>
<div class="menun">Buy what you need.<br /> <br /></div>
</div>
<div class="menu1">
<div class="menuit"><a href="{H.url_base}profile">PROFILE</a></div>
<div class="menuline"></div>
<div class="menup"><a href="{H.url_base}profile"><img src="/art/proa.png" width="100" height="100"></a></div>
<div class="menun">View and change how others see you.</div>
</div>
</div>
<div class="menu">
<div class="menu1">
<div class="menuit"><a href="{H.url_base}list">LIST</a></div>
<div class="menuline"></div>
<div class="menup"><a href="{H.url_base}list"><img src="/art/lista.png" width="100" height="100"></a></div>
<div class="menun">View the leaderboards.</div>
</div>
<div class="menu1">
<div class="menuit"><a href="{H.url_base}fight">FIGHT</a></div>
<div class="menuline"></div>
<div class="menup"><a href="{H.url_base}fight"><img src="/art/fighta.png" width="100" height="100"></a></div>
<div class="menun">Attack the others for fun and profit.</div>
</div>
<div class="menu1">
<div class="menuit"><a href="{H.url_base}trade">TRADE</a></div>
<div class="menuline"></div>
<div class="menup"><a href="{H.url_base}trade"><img src="/art/tradea.png" width="100" height="100"></a></div>
<div class="menun">Trade with the others.</div>
</div>
</div>
</div>
<div class="clear"></div>

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
	
		d.hello="Hello, "..d.name.."."
		
		d.action="<div class=\"log3\"><div class=\"logit\"><a href=\""..users.logout_url(d.srv.url).."\">Logout?</a></a></div>"
	else
		d.hello="Hello, Anon."
		d.action="<div class=\"log2\"><div class=\"logit\"><a href=\""..users.login_url(d.srv.url).."\">Login?</a></a></div>"
	
	end
	
	return replace([[
	
		<div class="chunk2">
			<div class="log">
				<div class="log1">
					<div class="logn">{hello}</div>
				</div>
					{action}
			</div>
		</div>
	</div>
	<div class="line"></div>
	<div class="clear"></div>
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
			
		d.score=num_to_thousands(d.player.score)
		d.bux=num_to_thousands(d.player.bux)
		
		return replace([[	

<div class="cont">
<div class="chunk4">
<div class="act1">
<div class="act1p">
<a href="{H.url_base}work"><img src="/art/work.png" width="30" height="30"></a>
</div>
</div>
<div class="act1">
<div class="act1p">
<a href="{H.url_base}shop"><img src="/art/shop.png" width="30" height="30"></a>
</div>
</div>
<div class="act1">
<div class="act1p">
<a href="{H.url_base}profile"><img src="/art/pro.png" width="30" height="30"></a>
</div>
</div>
<div class="act1">
<div class="act1p">
<a href="{H.url_base}list"><img src="/art/list.png" width="30" height="30"></a>
</div>
</div>
<div class="act1">
<div class="act1p">
<a href="{H.url_base}fight"><img src="/art/fight.png" width="30" height="30"></a>
</div>
</div>
<div class="act1">
<div class="act1p">
<a href="{H.url_base}trade"><img src="/art/trade.png" width="30" height="30"></a>
</div>
</div>
<div class="clear"></div>
</div>
</div>
		
<div class="cont">
<div class="chunk5">
<div class="hud">
<div class="hud1">
<div class="hudit">
{player.energy}
</div>
<div class="hud1">
<div class="hudp">
<img src="/art/energy.png">
</div>
<div class="hudn">
energy
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud1">
<div class="hudit">
{score}
</div>
<div class="hud1">
<div class="hudp">
<img src="/art/score.png">
</div>
<div class="hudn">
score
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud1">
<div class="hudit">
{bux}
</div>
<div class="hud1">
<div class="hudp">
<img src="/art/bux.png">
</div>
<div class="hudn">
bux
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud2">
<div class="hud2it">
{player.hoes}
</div>
<div class="hud2">
<div class="hud2p">
<img src="/art/hoes.png">
</div>
<div class="hud2n">
hoes
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud2">
<div class="hud2it">
{player.houses}
</div>
<div class="hud2">
<div class="hud2p">
<img src="/art/house.png">
</div>
<div class="hud2n">
houses
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud2">
<div class="hud2it">
{player.bros}
</div>
<div class="hud2">
<div class="hud2p">
<img src="/art/scare.png">
</div>
<div class="hud2n">
bros
</div>
</div>
</div>
</div>
</div>
<div class="clear"></div>
</div>
		
]],d)

	end
	
	return replace([[	
<div class="hoe_player_bar">
</div>
]],d)

end

-----------------------------------------------------------------------------
--
-- display a round row, for use in a "table" list of rounds 
--
-----------------------------------------------------------------------------
round_row=function(d)

	local r=d.round
	
	if r then
	
		d.speed=math.floor(60*60 / r.timestep) -- energy per hour
		d.start=os.date("%Y%m%d",r.created) -- 8 digit year-month-day number
		d.remaining=rough_english_duration(r.endtime-d.srv.time).." remaining" -- remaining play time
		if r.endtime-d.srv.time <= 0 then d.remaining="game over man" end
		d.players=r.players
		d.url=d.srv.url_base..r.id
			
		return replace([[	
<a class="hoe_round_row" href="{url}" style="display:block"> game {round.id} : 
<span class="hoe_round_row_speed">{speed}eph</span>
<span class="hoe_round_row_start">{start}</span>
<span class="hoe_round_row_end">{remaining}</span>
<span class="hoe_round_row_players">{players} players</span>
</a>
]],d)

	end
	
	return replace([[	
<div class="hoe_round_row">
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
	
		d.score=num_to_thousands(d.player.score)
		d.bux=num_to_thousands(d.player.bux)
			
		return replace([[	
<div class="hoe_player_row">
<span class="hoe_player_row_name">{player.name}</span>
<span class="hoe_player_row_score">score={score}</span>
<span class="hoe_player_row_bux">bux={bux}</span>
<span class="hoe_player_row_hoes">hoes={player.hoes}</span>
<span class="hoe_player_row_houses">houses={player.houses}</span>
<span class="hoe_player_row_bros">bros={player.bros}</span>
<span class="hoe_player_row_shout">{player.shout}</span>
</div>
]],d)

	end
	
	return replace([[	
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
		
		d.score=num_to_thousands(d.player.score)
		d.bux=num_to_thousands(d.player.bux)
		
		return replace([[	
<div class="hoe_player_base">
<span class="hoe_player_base_name">{player.name}</span>
<span class="hoe_player_base_score">score={score}</span>
<span class="hoe_player_base_bux">bux={bux}</span>
<span class="hoe_player_base_hoes">hoes={player.hoes}</span>
<span class="hoe_player_base_houses">houses={player.houses}</span>
<span class="hoe_player_base_bros">bros={player.bros}</span>
<span class="hoe_player_base_shout">{player.shout}</span>
</div>
]],d)

	end
	
	return replace([[	
<div class="hoe_player_base">
</div>
]],d)

end
			
-----------------------------------------------------------------------------
--
-- display player work form
--
-----------------------------------------------------------------------------
player_work_form=function(d)

	return replace([[	
<div class="hoe_player_work">

<form class="jNice" name="hoe_player_work_form" id="hoe_player_work_form" action="" method="POST" enctype="multipart/form-data">
<br/>
<br/>
A high payout will earn you less money but may convince new hoes to join you.<br/>
A low payout will earn you more money but may cause your hoes to leave.<br/>
<br/>

<a href="#" onclick="$('#hoe_player_work_form_payout').attr('value','0');">0%</a>
<a href="#" onclick="$('#hoe_player_work_form_payout').attr('value','25');">25%</a>
<a href="#" onclick="$('#hoe_player_work_form_payout').attr('value','50');">50%</a>
<a href="#" onclick="$('#hoe_player_work_form_payout').attr('value','75');">75%</a>
<a href="#" onclick="$('#hoe_player_work_form_payout').attr('value','100');">100%</a>
<br/>
<input type="text" name="payout" id="hoe_player_work_form_payout" value="{payout}"/>% payout
<br/>

<input type="submit" name="submit" value="Work!"/>

</form>

</div>
]],d)

end

-----------------------------------------------------------------------------
--
-- display player work result
--
-----------------------------------------------------------------------------
player_work_result=function(d)

	d.sbux=""
	d.shoes=""
	d.sbros=""

	if d.result.total_bux>0 then
		d.total_bux=num_to_thousands(d.result.total_bux)
		d.bux=num_to_thousands(d.result.bux)
		d.sbux=replace([[
<span>
Your hoes worked hard and earned a total of {total_bux} bux giving you {bux} bux after expenses.
</span><br/>
]],d)
	end
	
	if d.result.hoes>0 then
		d.one=d.result.hoes
		d.shoes=replace([[
<span>
{one} hoe joined your buisness.
</span><br/>
]],d)
	elseif d.result.hoes<0 then
		d.one=-d.result.hoes
		d.shoes=replace([[
<span>
{one} hoe left your buisness.
</span><br/>
]],d)
	end

	if d.result.bros>0 then
		d.one=d.result.bros
		d.sbros=replace([[
<span>
{one} bro joined your buisness.
</span><br/>
]],d)
	end
	
	return replace([[	
<div class="hoe_player_result">
{sbux}
{shoes}
{sbros}
</div>
]],d)

end

-----------------------------------------------------------------------------
--
-- suggest an act
--
-----------------------------------------------------------------------------
request_login=function(d)

	d.action="<a href=\""..users.login_url(d.srv.url).."\">Login</a>"
	
	return replace([[
	
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
	
	return replace([[
	
<div class="hoe_acts">
Click {action} to {action} this game.
</div>

]],d)

end

			
			
		
			
		
