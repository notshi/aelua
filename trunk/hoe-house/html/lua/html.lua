

local users=require("wetgenes.aelua.users")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace

local table=table
local string=string
local math=math
local os=os

local pairs=pairs

module("html")

-----------------------------------------------------------------------------
--
-- turn a number of seconds into a rough duration
--
-----------------------------------------------------------------------------
function rough_english_duration(t)
	t=math.floor(t)
	if t>=2*365*24*60*60 then
		return math.floor(t/(365*24*60*60)).." years"
	elseif t>=2*30*24*60*60 then
		return math.floor(t/(30*24*60*60)).." months" -- aproximate months
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

-----------------------------------------------------------------------------
--
-- turn an integer number into a string with three digit grouping
--
-----------------------------------------------------------------------------
function num_to_thousands(n)
	local p=math.floor(n) -- remove the fractions
	if p<0 then p=-p end -- remove the sign
	local s=string.format("%d",p) -- force format integer part only?
	local len=string.len(s) -- total length of number
	local skip=len%3 -- size of first batch
	local t={}
	if skip>0 then -- 1 or 2 digits
		t[#t+1]=string.sub(s,1,skip)
	end
	for i=skip,len-3,3 do -- batches of 3 digits
		t[#t+1]=string.sub(s,i+1,i+3)
	end
	local s=table.concat(t,",") -- join it back together with commas every 3 digits
	if n<0 then return "-"..s else return s end -- put the sign back and return it
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

<link rel="stylesheet" type="text/css" href="/css/hoe.css" /> 

<script type="text/javascript" src="/js/jquery.js"></script>


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
	
	elseif d.app_name and d.app_link then
	
		mods=" app <a href=\""..d.app_link.."\">"..d.app_name.."</a>"
		
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
{aelua} is a {lua} core and framework compatible with {appengine}.<br/>
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
		
		d.action="<div class=\"log3\"><div class=\"logit\"><a href=\""..users.logout_url(d.srv.url).."\">Logout?</a></div></div>"
	else
		d.hello="Hello, Anon."
		d.action="<div class=\"log2\"><div class=\"logit\"><a href=\""..users.login_url(d.srv.url).."\">Login?</a></div></div>"
	
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
<div class="hud2">
<div class="hud2it">
<b>{player.energy}</b>
</div>
<div class="hud2">
<div class="hud2n">
<img src="/art/energyb.png"> energy
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud1">
<div class="hudit">
<b>{score}</b>
</div>
<div class="hud1">
<div class="hudn">
<img src="/art/scoreb.png"> score
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud1">
<div class="hudit">
<b>{bux}</b>
</div>
<div class="hud1">
<div class="hudn">
<img src="/art/buxb.png"> bux
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud2">
<div class="hud2it">
<b>{player.hoes}</b>
</div>
<div class="hud2">
<div class="hud2n">
<img src="/art/hoesb.png"> hoes
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud2">
<div class="hud2it">
<b>{player.houses}</b>
</div>
<div class="hud2">
<div class="hud2n">
<img src="/art/housesb.png"> houses
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud2">
<div class="hud2it">
<b>{player.bros}</b>
</div>
<div class="hud2">
<div class="hud2n">
<img src="/art/scareb.png"> bros
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
-- display most player info on their profile
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

	for i,v in pairs{1,5,10} do
		if v==d.xwork then
			d["check"..v]=" checked=\"true\""
		end
	end

	return replace([[	
<div class="cont">
<div class="chunk7">
<div class="chunk8">
<div class="formt">
A <b>high</b> payout will earn you less money but may convince new hoes to <b>join</b> you. <br />
A <b>low</b> payout will earn you more money but may cause your hoes to <b>leave</b>.
</div>
<div class="formline">
</div>
</div>
<div class="chunk8">
<div class="chunk9">
	<div class="formp1">
		<div class="formn">
			<a href="#" onclick="$('#hoe_player_work_form_payout').attr('value','0');">0%</a>
		</div>
	</div>
	<div class="formp2">
		<div class="formn">
			<a href="#" onclick="$('#hoe_player_work_form_payout').attr('value','25');">25%</a>
		</div>
	</div>
	<div class="formp3">
		<div class="formn">
			<a href="#" onclick="$('#hoe_player_work_form_payout').attr('value','50');">50%</a>
		</div>
	</div>
	<div class="formp4">
		<div class="formn">
			<a href="#" onclick="$('#hoe_player_work_form_payout').attr('value','75');">75%</a>
		</div>
	</div>
	<div class="formp5">
		<div class="formn">
			<a href="#" onclick="$('#hoe_player_work_form_payout').attr('value','100');">100%</a>
		</div>
	</div>
</div>
</div>
<div class="chunk8">
<div class="chunk9">
<div class="formt">
	<div id="workit" class="formi">
	
	<form class="form" name="hoe_player_work_form" id="hoe_player_work_form" action="" method="POST" enctype="multipart/form-data">

	<input class="percent" type="text" name="payout" id="hoe_player_work_form_payout" value="{payout}"/> % payout
	<button type="submit" name="submit">Work!</button>
	<br />
	<input class="radio" type="radio" name="x" value="1"{check1}/>x1
	<input class="radio" type="radio" name="x" value="5"{check5}/>x5
	<input class="radio" type="radio" name="x" value="10"{check10}/>x10<br/>

	</form>
	
	</div>
</div>
</div>
</div>
</div>
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
<div class="cont">
<div class="chunk6">
<div class="alert">
Your hoes worked hard and farmed a total of <img src="/art/buxb.png"> <b>{total_bux}</b> bux giving you <img src="/art/buxb.png"> <b>{bux}</b> bux after payout.
</div>
<div class="clear"></div>
</div>
</div>
]],d)
	end
	
	if d.result.hoes>0 then
		d.one=d.result.hoes
		d.s=""
		if d.one>1 then d.s="s" end
		d.shoes=replace([[
<div class="cont">
<div class="chunk6">
<div class="alert">
<img src="/art/hoes.png"> <b>{one}</b> hoe{s} joined your business.
</div>
<div class="clear"></div>
</div>
</div>
]],d)
	elseif d.result.hoes<0 then
		d.one=-d.result.hoes
		d.s=""
		if d.one>1 then d.s="s" end
		d.shoes=replace([[
<div class="cont">
<div class="chunk6a">
<div class="alert">
<img src="/art/hoes.png"> <b>{one}</b> hoe{s} left your business.
</div>
<div class="clear"></div>
</div>
</div>
]],d)
	end

	if d.result.bros>0 then
		d.one=d.result.bros
		d.s=""
		if d.one>1 then d.s="s" end
		d.sbros=replace([[
<div class="cont">
<div class="chunk6">
<div class="alert">
<img src="/art/scare.png"> <b>{one}</b> bro{s} joined your business.
</div>
<div class="clear"></div>
</div>
</div>
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

<div class="cont">
<div class="chunk6">
<div class="alert">
Please {action}	if you wish to join this game.
</div>

<div class="clear"></div>
</div>
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

<div class="cont">
<div class="chunk6">
<div class="alert">
Click {action} to {action} this game.
</div>

<div class="clear"></div>
</div>
</div>

]],d)

end

-----------------------------------------------------------------------------
--
-- missing content
--
-----------------------------------------------------------------------------
missing_content=function(d)

	return replace([[
<div class="missing_content">MISSING CONTENT</div>
]],d)

end


-----------------------------------------------------------------------------
--
-- missing content
--
-----------------------------------------------------------------------------
player_needed=function(d)

	if d.H.user then
		d.act=users.put_act(d.H.user,{cmd="join",check=d.H.user_data_name})
		return request_join(d)
	else
		return request_login(d)
	end

end
	
-----------------------------------------------------------------------------
--
-- display player work form
--
-----------------------------------------------------------------------------
player_shop_form=function(d)

	d.houses_bux=num_to_thousands(d.cost.houses)
	d.bros_bux=num_to_thousands(d.cost.bros)
	d.gloves_bux=num_to_thousands(d.cost.gloves)
	d.sticks_bux=num_to_thousands(d.cost.sticks)
	d.manure_bux=num_to_thousands(d.cost.manure)

	return replace([[	
<div class="hoe_player_shop">

<form class="notjNice" name="hoe_player_shop_form" id="hoe_player_shop_form" action="" method="POST" enctype="multipart/form-data">


Buy <input type="text" name="houses" id="hoe_player_work_form_houses" value="0" style="width:100px;"/> houses at {houses_bux} bux each.<br/>
Buy <input type="text" name="bros" id="hoe_player_work_form_bros" value="0" style="width:100px;"/> bros at {bros_bux} bux each.<br/>
Buy <input type="text" name="gloves" id="hoe_player_work_form_gloves" value="0" style="width:100px;"/> gloves at {gloves_bux} bux each.<br/>
Buy <input type="text" name="sticks" id="hoe_player_work_form_sticks" value="0" style="width:100px;"/> sticks at {sticks_bux} bux each.<br/>
Buy <input type="text" name="manure" id="hoe_player_work_form_manure" value="0" style="width:100px;"/> manure at {manure_bux} bux each.<br/>


<input type="submit" name="submit" value="Buy!"/>

</form>

</div>
]],d)

end

-----------------------------------------------------------------------------
--
-- display player work form
--
-----------------------------------------------------------------------------
player_shop_result=function(d)

	if d.fail then
		d.need=num_to_thousands(-d.result.bux or 0)
		return replace([[	
<div class="hoe_player_shop_results">
You do not have the {need} bux needed.
</div>
]],d)
	else

		return replace([[	
<div class="hoe_player_shop_results">
</div>
]],d)
	end
end

-----------------------------------------------------------------------------
--
-- display player shop results
--
-----------------------------------------------------------------------------
player_shop_results=function(d)


	return replace([[	
<div class="hoe_player_shop_results">

</div>
]],d)

end
