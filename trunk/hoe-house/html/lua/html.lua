

local users=require("wetgenes.aelua.users")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local table=table
local string=string
local math=math
local os=os

local pairs=pairs
local tostring=tostring

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

	d.jquery_js="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
	d.jquery_ui_js="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.2/jquery-ui.min.js"
	d.swfobject_js="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"
	
	if d.srv.url_slash[3]=="host.local:8080" then -- a local shop only servs local people
		d.jquery_js="/js/jquery-1.4.2.min.js"
		d.jquery_ui_js="/js/jquery-ui-1.8.2.custom.min.js"
		d.swfobject_js="/js/swfobject.js"
	end
	
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

<link rel="stylesheet" type="text/css" href="/css/jquery/smoothness/jquery-ui-1.8.2.custom.css" />
<link rel="stylesheet" type="text/css" href="/css/hoe.css" /> 

<script type="text/javascript" src="{jquery_js}"></script>
<script type="text/javascript" src="{jquery_ui_js}"></script>
<script type="text/javascript" src="{swfobject_js}"></script>



 </head>
<body>

<div class="wrapper">
<div class="maincont">	
<div class="cont">
	<div class="header" id="header">
		<a href="/"><img src="/art/hoe.960x180.png" width="960" height="180"></a>
		<a id="alfa" href="http://forum.wetgenes.com" target="_new"></a>
		<a id="tv_switch" href="#" onclick='swfobject.embedSWF("http://www.wetgenes.com/link/WetV.swf", "header", "960", "480", "8");return false;'>Switch on TV?</a>
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



</div>
	<div class="push"></div>
</div>
<div class="footer">
	<div class="cont">
		<div class="line"></div>
		<div class="desc">
			{report}
		</div>
		<div class="desc1">
			Send in your bug reports and visit the <a href="http://forum.wetgenes.com" target="_new">Forum</a> for more information.
		</div>
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

	return replace([[
<br/>
<div class="cont">
	<div class="chunk">
		<div class="intro">
			<div class="illgame1"></div>
			<div class="intro1">
				{hoehouse} is a friendly hommage to {whorehouse}.<br/>
				{hoehouse} is an example {aelua} app.<br/>
				<br/>
				{aelua} is a {lua} core and framework compatible with {appengine}.<br/>
				{aelua} and {hoehouse} are designed and developed by {wetgenes}.<br/>
			</div>
		</div>
	</div>
	<div class="clear"></div>
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

	local user=d.H and d.H.user
	local hash=d.H and d.H.sess and d.H.sess.key and d.H.sess.key.id
	if user then
	
		d.name="<span title=\""..user.cache.email.."\" >"..(user.cache.name or "?").."</span>"
	
		d.hello="Hello, "..d.name.."."
		
--		d.action="<div class=\"log3\"><div class=\"logit\"><a href=\""..users.logout_url(d.srv.url).."\">Logout?</a></div></div>"
		d.action="<div class=\"log3\"><div class=\"logit\"><a href=\"/dumid/logout/"..hash.."/?continue="..url_esc(d.srv.url).."\">Logout?</a></div></div>"
	else
		d.hello="Hello, Anon."
--		d.action="<div class=\"log2\"><div class=\"logit\"><a href=\""..users.login_url(d.srv.url).."\">Login?</a></div></div>"
		d.action="<div class=\"log2\"><div class=\"logit\"><a href=\"/dumid/login/?continue="..url_esc(d.srv.url).."\">Login?</a></div></div>"
	
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
<div class="act">
<div class="actp">
<a href="{H.url_base}work"><img src="/art/work.png" width="30" height="30"></a>
</div>
</div>
<div class="act">
<div class="actp">
<a href="{H.url_base}shop"><img src="/art/shop.png" width="30" height="30"></a>
</div>
</div>
<div class="act">
<div class="actp">
<a href="{H.url_base}profile"><img src="/art/pro.png" width="30" height="30"></a>
</div>
</div>
<div class="act">
<div class="actp">
<a href="{H.url_base}list"><img src="/art/list.png" width="30" height="30"></a>
</div>
</div>
<div class="act">
<div class="actp">
<a href="{H.url_base}fight"><img src="/art/fight.png" width="30" height="30"></a>
</div>
</div>
<div class="act">
<div class="actp">
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
<i id="player_energy">{player.energy}</i>
<script type="text/javascript">
function show_energy(nam,num,frac,upd)
{
	var start_time=(new Date()).getTime();
	var tid;
	var update=function() {
		var now_time=(new Date()).getTime();
		var t=(now_time-start_time)/upd; // grows over time
		t=(t+frac+num);
		if(t>300) // max
		{
			t=300;
			clearInterval(tid);
		}
		$(nam).text(t.toFixed(2));
	};
	update();
	tld=setInterval(update,1000);
}
$(function(){show_energy("#player_energy",{player.energy},{H.energy_frac},{H.energy_step}*1000);});

</script>
</div>
<div class="hud2">
<div class="hud2n">
<img src="/art/energyb.png"> Energy
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud1">
<div class="hudit">
<i>{score}</i>
</div>
<div class="hud1">
<div class="hudn">
<img src="/art/scoreb.png"> Score
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud1">
<div class="hudit">
<i>{bux}</i>
</div>
<div class="hud1">
<div class="hudn">
<img src="/art/buxb.png"> Bux
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud2">
<div class="hud2it">
<i>{player.hoes}</i>
</div>
<div class="hud2">
<div class="hud2n">
<img src="/art/hoesb.png"> Hoes
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud2">
<div class="hud2it">
<i>{player.houses}</i>
</div>
<div class="hud2">
<div class="hud2n">
<img src="/art/housesb.png"> Houses
</div>
</div>
</div>
<div class="hudline"></div>
<div class="hud2">
<div class="hud2it">
<i>{player.bros}</i>
</div>
<div class="hud2">
<div class="hud2n">
<img src="/art/scareb.png"> Bros
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
round_row_header=function(d)
	return replace([[
	
<div class="cont">
	<div class="chunk3a">
		<div class="chunk3ait">
			Choose the round you want to join.
		<div class="chunk3line"></div>
		</div>
		<div class="clear"></div>
	</div>	
	<div class="chunk8a">	
	<div class="chunk8b">
		<div class="game2">
			Round #	
		</div>
		<div class="game">
			Players
		</div>
		<div class="game">
			Speed
		</div>
		<div class="game">
			Start Date
		</div>
		<div class="game">
			Time Remaining
		</div>
		<div class="clear"></div>
	</div>
	
]],d)
end	

round_row_footer=function(d)
	return replace([[
	
	<div class="clear"></div>
	<div class="chunk8b">
		<div class="game3">
			Round #	
		</div>
		<div class="game">
			Players
		</div>
		<div class="game">
			Speed
		</div>
		<div class="game">
			Start Date
		</div>
		<div class="game">
			Time Remaining
		</div>
		<div class="clear"></div>
	</div>
</div>
</div>
	
]],d)
end

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
	
	<div class="chunk8b">
		<div class="game1">
			<a class="hoe_round_row" href="{url}">Round <i>{round.id}</i></a>	
		</div>
		<div class="game">
			<a class="hoe_round_row" href="{url}"><i>{players}</i></a>
		</div>
		<div class="game">
			<a class="hoe_round_row" href="{url}"><i>{speed}</i> eph</a>
		</div>
		<div class="game">
			<a class="hoe_round_row" href="{url}"><i>{start}</i></a>
		</div>
		<div class="game">
			<a class="hoe_round_row" href="{url}"><i>{remaining}</i></a>
		</div>
		<div class="clear"></div>
	</div>

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
player_row_header=function(d)
	d.random=math.random(1,3)
	return replace([[
	
<div class="cont">
	<div class="chunk3a">
		<div class="chunk3ait">
			<img src="/art/list.png" width="30" height="30"> List
		<div class="chunk3line"></div>
		</div>
		<div class="clear"></div>
	</div>	
	<div class="illlist{random}"></div>
	<div class="chunk8a">
		<div class="chunk8b">
			<div class="listat">Player Name</div>
			<div class="listat"><img src="/art/scoreb.png"> Score</div>
			<div class="listat"><img src="/art/buxb.png"> Bux</div>
			<div class="listbt"><img src="/art/hoesb.png"> Hoes</div>
			<div class="listbt"><img src="/art/housesb.png"> Houses</div>
			<div class="listbt"><img src="/art/scareb.png"> Bros</div>
			<div class="listct">Shout</div>
		</div>
		<div class="clear"></div>
	
]],d)
end

player_row_footer=function(d)
	return replace([[
	
		<div class="clear"></div>
		<div class="chunk8b">
			<div class="listat">Player Name</div>
			<div class="listat"><img src="/art/scoreb.png"> Score</div>
			<div class="listat"><img src="/art/buxb.png"> Bux</div>
			<div class="listbt"><img src="/art/hoesb.png"> Hoes</div>
			<div class="listbt"><img src="/art/housesb.png"> Houses</div>
			<div class="listbt"><img src="/art/scareb.png"> Bros</div>
			<div class="listct">Shout</div>
		</div>
		<div class="clear"></div>
	</div>
<a href="{url}">TOP</a>
<a href="{url}?off={page.prev}">PREV</a>
<a href="{url}?off={page.next}">NEXT</a>
</div>

	
]],d)
end

player_row=function(d)

	if d.player then
	
		d.score=num_to_thousands(d.player.score)
		d.bux=num_to_thousands(d.player.bux)
			
		return replace([[

		<div class="chunk8b">
			<div class="lista"><a href="{H.url_base}profile/{player.id}">{player.name}</a></div>
			<div class="lista"><i>{score}</i></div>
			<div class="lista"><i>{bux}</i></div>
			<div class="listb"><i>{player.hoes}</i></div>
			<div class="listb"><i>{player.houses}</i></div>
			<div class="listb"><i>{player.bros}</i></div>
			<div class="listc">{player.shout}</div>
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
<div class="cont">
	<div class="chunk3">
		<div class="chunk3it">
			<img src="/art/shop.png" width="30" height="30"> Shop
		<div class="chunk3line"></div>
		</div>
		<div class="clear"></div>
	</div>
	<div class="illshop1"></div>
	<div class="chunk8">
		<div class="chunk9">
		<div class="formta">
			<span class="hoe_player_base_name">{player.name}</span>
			<span class="hoe_player_base_score">score={score}</span>
			<span class="hoe_player_base_bux">bux={bux}</span>
			<span class="hoe_player_base_hoes">hoes={player.hoes}</span>
			<span class="hoe_player_base_houses">houses={player.houses}</span>
			<span class="hoe_player_base_bros">bros={player.bros}</span>
			<span class="hoe_player_base_shout">{player.shout}</span>
		</div>
		</div>
	</div>
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
		else
			d["check"..v]=""
		end
	end
	
	for i,v in pairs{0,25,50,75,100} do
		d["set"..v]="$('#hoe_player_work_form_payout').attr('value','"..v.."');$('#hoe_player_work_form_slide').slider('option','value',"..v..");return false"
	end
	
	return replace([[	
<div class="cont">
<div class="chunk7">
	<div class="chunk8">
		<div class="formt">
			A <b>high</b> payout will earn you less money but may convince new hoes to <b>join</b> you. <br />
			A <b>low</b> payout will earn you more money but may cause your hoes to <b>leave</b>.
		</div>
		<div class="formline"></div>
	</div>
	<div class="chunk8">
		<div class="chunk9">
			<div class="formp1">
				<div class="formn">
					<i><a href="#" onclick="{set0}">0%</a></i>
				</div>
			</div>
			<div class="formp2">
				<div class="formn">
					<i><a href="#" onclick="{set25}">25%</a></i>
				</div>
			</div>
			<div class="formp3">
				<div class="formn">
					<i><a href="#" onclick="{set50}">50%</a></i>
				</div>
			</div>
			<div class="formp4">
				<div class="formn">
					<i><a href="#" onclick="{set75}">75%</a></i>
				</div>
			</div>
			<div class="formp5">
				<div class="formn">
					<i><a href="#" onclick="{set100}">100%</a></i>
				</div>
			</div>
		</div>
	</div>
	<div class="chunk8">
	
		<form class="form" name="hoe_player_work_form" id="hoe_player_work_form" action="" method="POST" enctype="multipart/form-data">
		<div id="hoe_player_work_form_slide" class="slide"></div>
		
		
		<div id="workit" class="formi">
		<input class="percent" type="text" name="payout" id="hoe_player_work_form_payout" value="{payout}"/><div class="formina"><div class="forminb">% Payout</div></div>
		
		<div class="forminline"></div>
		
		<button type="submit" name="submit">Work!</button>
		
		<div class="formin">
		<div class="formin">
		<input class="radio" type="radio" name="x" value="1"{check1}/>x1
		</div>
		<div class="formin">
		<input class="radio" type="radio" name="x" value="5"{check5}/>x5
		</div>
		<div class="formin">
		<input class="radio" type="radio" name="x" value="10"{check10}/>x10
		</div>
		</div>

		</form>
		
		<div class="clear"></div>
		</div>
		

	</div>
</div>
</div>

<script>
$(document).ready(function() {
	$("#hoe_player_work_form_slide").slider({ min:0,max:100,value:{payout},
		slide: function(event, ui) {
			$('#hoe_player_work_form_payout').attr('value',ui.value);
			}
		});	
	$('#hoe_player_work_form_payout').bind("change keyup", function() { 
		$('#hoe_player_work_form_slide').slider('option','value',$('#hoe_player_work_form_payout').attr('value'));
		}); 
	});
</script>

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
	d.random=math.random(1,3)

	if d.result.total_bux>0 then
		d.total_bux=num_to_thousands(d.result.total_bux)
		d.bux=num_to_thousands(d.result.bux)
		d.sbux=replace([[
<div class="cont">
<div class="illwork{random}">
<div class="chunk6c">
<div class="alert">
Your hoes worked hard and farmed a total of <img src="/art/buxb.png"> <i>{total_bux}</i> bux giving you <img src="/art/buxb.png"> <i>{bux}</i> bux after payout.
</div>
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
<div class="illhoe{random}">
<div class="chunk6b">
<div class="alert">
<img src="/art/hoes.png"> <i>{one}</i> hoe{s} joined your business.
</div>
</div>
</div>
<div class="clear"></div>
</div>
]],d)
	elseif d.result.hoes<0 then
		d.one=-d.result.hoes
		d.s=""
		if d.one>1 then d.s="s" end
		d.shoes=replace([[
<div class="cont">
<div class="illleave{random}">
<div class="chunk6a">
<div class="alert">
<img src="/art/hoes.png"> <i>{one}</i> hoe{s} left your business.
</div>
</div>
</div>
<div class="clear"></div>
</div>
]],d)
	end

	if d.result.bros>0 then
		d.one=d.result.bros
		d.s=""
		if d.one>1 then d.s="s" end
		d.sbros=replace([[
<div class="cont">
<div class="illbro{random}">
<div class="chunk6b">
<div class="alert">
<img src="/art/scare.png"> <i>{one}</i> bro{s} joined your business.
</div>
</div>
</div>
<div class="clear"></div>
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

	d.action="<a href=\"/dumid/login/?continue="..url_esc(d.srv.url).."\">Login</a>"
	
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
<div class="chunk">
	<span style="text-align:'center';font-size:23px;">
		<br />
		Herro, you've reached the future.
		We haven't made this yet. <br />
		Send all bugs & complaints to the <a href="http://forum.wetgenes.com/" target="_new">forum</a>. We have repellents.
	</span>
</div>
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
			
<div class="cont">
	<div class="chunk3a">
		<div class="chunk3ait">
			<img src="/art/shop.png" width="30" height="30"> Shop
		<div class="chunk3line"></div>
		</div>
		<div class="clear"></div>
	</div>
	<div class="illshop1"></div>
	<div class="chunk8a">
	<div class="formta">
	<form class="notjNice" name="hoe_player_shop_form" id="hoe_player_shop_form" action="" method="POST" enctype="multipart/form-data">

	<div id="buyit">
		Buy <i><input type="text" name="houses" id="hoe_player_work_form_houses" value="0" style="width:100px;"/></i> <img src="/art/housesb.png"> houses at <img src="/art/buxb.png"> <i>{houses_bux}</i> bux each.
		<div class="formline1"></div>
		Buy <i><input type="text" name="bros" id="hoe_player_work_form_bros" value="0" style="width:100px;"/></i> <img src="/art/scareb.png"> bros at <img src="/art/buxb.png"> <i>{bros_bux}</i> bux each.
		<div class="formline1"></div>
		Buy <i><input type="text" name="gloves" id="hoe_player_work_form_gloves" value="0" style="width:100px;"/></i> <img src="/art/glovesb.png"> gloves at <img src="/art/buxb.png"> <i>{gloves_bux}</i> bux each.
		<div class="formline1"></div>
		Buy <i><input type="text" name="sticks" id="hoe_player_work_form_sticks" value="0" style="width:100px;"/></i> <img src="/art/sticksb.png"> sticks at <img src="/art/buxb.png"> <i>{sticks_bux}</i> bux each.
		<div class="formline1"></div>

		<button class="button" type="submit" name="submit" value="Buy!">Buy!</button>
	</div>
	
	</form>
	</div>
	</div>
	
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



-----------------------------------------------------------------------------
--
-- display a players profile
--
-----------------------------------------------------------------------------
player_profile=function(d)

		d.score=num_to_thousands(d.player.score)
		d.bux=num_to_thousands(d.player.bux)
		
		d.form=""
		if d.edit then -- we can edit our profile
		
			d.form=replace([[	
<div class="cont">
	<div class="chunk3a">
		<div class="chunk3ait">
			<img src="/art/pro.png" width="30" height="30"> Profile
		<div class="chunk3line"></div>
		</div>
		<div class="clear"></div>
	</div>	
	<div class="illpro1"></div>
	<div class="chunk8c">
		<div class="chunk8b">
		
			<div class="pro1">
				<div class="pro1a">
					
					<div class="pro1b">
						<form action="" method="POST" enctype="multipart/form-data">
						<div class="pro1c">
							<div class="pro1c">
								Name:
							</div>
							<div class="pro1c1">
								( Max. 20 char )
							</div>
							<div class="pro1c">
								<button type="submit" name="do_name">Change name</button>
							</div>
						</div>
						<div class="pro1d">	
							<input type="text" name="name" id="profile_name" maxlength="20" value="{player.name}" /><br/>
						</div>
						</form>
					</div>
					<div class="clear"></div>
					<div class="pro1b1">	
						<form action="" method="POST" enctype="multipart/form-data">
						<div class="pro1c">
							<div class="pro1c">
								Shout:
							</div>
							<div class="pro1c1">
								( Max. 100 char )
							</div>
							<div class="pro1c">
								<button type="submit" name="do_shout">Change shout</button>
							</div>
						</div>
						<div class="pro1d">
							<input type="text" name="shout" id="profile_shout" maxlength="100" value="{player.shout}" /><br/>
						</div>
						</form>
					</div>
					<div class="clear"></div>


	
]],d)
		elseif d.fight then
			d.form=replace([[	
<div class="cont">
	<div class="chunk3a">
		<div class="chunk3ait">
			<img src="/art/pro.png" width="30" height="30"> Profile
		<div class="chunk3line"></div>
		</div>
		<div class="clear"></div>
	</div>	
	<div class="chunk8c">
		<div class="chunk8b">
		
			<div class="pro1">
				<div class="pro1a">
					
					<div class="prorob">
						<a href="{H.url_base}fight/{player.id}/rob">Rob <img src="/art/buxb.png"> bux from {player.name}</a>
					</div>

]],d)
		end
		
		return replace([[
{form}
					<div class="pro1b1">
						<div class="pro1c2">
							Shout:
						</div>
						<div class="pro1d1">
							{player.shout}
						</div>
					</div>
					<div class="clear"></div>
				</div>
			</div>
		<div class="pro2">
			<div class="pro2a1">
				<div class="pro2b">
					<div class="pro2id">
						<i>#{player.id}</i>
					</div>
					<div class="pro2c">
						{player.name}
					</div>
				</div>
				<div class="clear"></div>
			</div>
			<div class="pro2a">
				<div class="pro2b">
					<div class="pro2tit">
						Inventory
					</div>
				</div>
				<div class="clear"></div>
				<div class="pro2b">
					<div class="pro2d1">
						<div class="pro2d">
							<i>{score}</i>
						</div>
						<div class="procat1">
							<img src="/art/scoreb.png"> Score
						</div>
					</div>
					<div class="pro2d2">
						<div class="pro2d">
							<i>{bux}</i>
						</div>
						<div class="procat1">
							<img src="/art/buxb.png"> Bux
						</div>
					</div>
				</div>
				<div class="pro2b">
					<div class="pro2e1">
						<div class="pro2e">
							<i>{player.hoes}</i>
						</div>
						<div class="procat2">
							<img src="/art/hoesb.png"> Hoes
						</div>
					</div>
					<div class="pro2e1">
						<div class="pro2e">
							<i>{player.houses}</i>
						</div>
						<div class="procat2">
							<img src="/art/housesb.png"> Houses
						</div>
					</div>
					<div class="pro2e2">
						<div class="pro2e">
							<i>{player.bros}</i>
						</div>
						<div class="procat2">
							<img src="/art/scareb.png"> Bros
						</div>
					</div>
				</div>
				<div class="pro2b">
					<div class="pro2e1">
						<div class="pro2e">
							<i>{player.gloves}</i>
						</div>
						<div class="procat2">
							Gloves
						</div>
					</div>
					<div class="pro2e1">
						<div class="pro2e">
							<i>{player.manure}</i>
						</div>
						<div class="procat2">
							Manure
						</div>
					</div>
					<div class="pro2e2">
						<div class="pro2e">
							<i>{player.sticks}</i>
						</div>
						<div class="procat2">
							Sticks
						</div>
					</div>
					<div class="clear"></div>
				</div>
			</div>
		</div>

		</div>
		<div class="clear"></div>
	</div>	
</div>
]],d)

end


-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_header=function(d)
	return replace([[
<br />
Only the best offer in each catagory is available to buy, so you should consider selling for less than that price if you want a quick sell.<br />
Remember that your trade offer will sit in the queue for a random amount of time, possibly a couple of hours before it shows up for anyone to buy.<br />
You might want to keep checking this page in case someone is offering a good deal.<br />
<br />
<div>
]],d)
end
-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_footer=function(d)
	return replace([[
</div>
]],d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_row=function(d)

	d.form=replace([[
<form action="{url}" method="POST" enctype="multipart/form-data">
<button type="submit" class="button">Sell!</button>
<input type="hidden" name="cmd" value="sell" /> 
<input type="hidden" name="trade" value="{trade.offer}4{trade.seek}" /> 
<input type="text" name="count" value="0" size="3" class="field"/> {trade.offer}
for <input type="text" name="cost" value="0" size="3" class="field"/> {trade.seek} each.
</form>
]],d)

	if not d.best then -- none available	
		return replace([[
<form action="{url}" method="POST" enctype="multipart/form-data">
<input type="hidden" name="key" value="0" /> 
<input type="hidden" name="cmd" value="buy" /> 
<input type="hidden" name="count" value="0" /> 
<input type="hidden" name="cost" value="0" /> 
<input type="hidden" name="trade" value="{trade.offer}4{trade.seek}" /> 
<button type="submit" class="button" disabled="disabled">Buy!</button>
noone is offering any {trade.offer} for {trade.seek}
</form>
{form}<br/>
]],d)
	
	end

	return replace([[
<form action="{url}" method="POST" enctype="multipart/form-data">
<input type="hidden" name="key" value="{best.id}" /> 
<input type="hidden" name="cmd" value="buy" /> 
<input type="hidden" name="count" value="{best.count}" /> 
<input type="hidden" name="cost" value="{best.cost}" /> 
<input type="hidden" name="trade" value="{best.offer}4{best.seek}" /> 
<button type="submit" class="button">Buy!</button>
player <a href="{H.url_base}profile/{best.player}">#{best.player}</a> is offering {best.count} {best.offer} for {best.price} {best.seek} ( {best.cost} {best.seek} each )
</form>
{form}<br/>
]],d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_buy_fail=function(d)

	return replace([[
<div>
<br/>
Failed to buy anything, maybe somebody else bought it first...
<br/>
<br/>
<div>
]],d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_buy_fail_cost=function(d)

	return replace([[
<div>
<br/>
You can not afford to buy that.
<br/>
<br/>
<div>
]],d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_buy=function(d)

	return replace([[
<div>
<br/>
Congratulations. You just bought {trade.count} {trade.offer} for {trade.price} {trade.seek}
from player <a href="{H.url_base}profile/{trade.player}">#{trade.player}</a> 
<br/>
<br/>
<div>
]],d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_sell=function(d)

	return replace([[
<div>
<br/>
Congratulations. You just offered {trade.count} {trade.offer} for {trade.price} {trade.seek}.<br/>
The {trade.offer} have been placed in escrow.<br/>
Now you must wait for it to be added to the queue and for a buyer.<br/>
<br/>
<div>
]],d)

end
