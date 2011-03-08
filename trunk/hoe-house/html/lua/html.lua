

local log=require("wetgenes.aelua.log").log

local sys=require("wetgenes.aelua.sys")
local waka=require("wetgenes.waka")
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
local require=require

module("html")

local base_html=require("base.html")

-----------------------------------------------------------------------------
--
-- load and parse plates.html
--
-----------------------------------------------------------------------------

base_html.import(_M)

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
		return math.floor(t/(30*24*60*60)).." months" -- approximate months
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
about=function(d)

	d=d or {}
	d.hoehouse="<a href=\"http://hoe-house.appspot.com/\">hoe house</a>"
	d.whorehouse="<a href=\"http://whorehouse.naken.cc/\">whore house</a>"
	d.aelua="<a href=\"http://code.google.com/p/aelua/\">aelua</a>"
	d.lua="<a href=\"http://www.lua.org/\">lua</a>"
	d.appengine="<a href=\"http://code.google.com/appengine/\">appengine</a>"
	d.wetgenes="<a href=\"http://www.wetgenes.com/\">wetgenes</a>"

	return replace(get_plate("about"),d)

end

-----------------------------------------------------------------------------
--
-- a home / tabs / next page area
--
-----------------------------------------------------------------------------
hoe_menu_items=function(d)
		
	return replace(get_plate("hoe_menu_items"),d)

end

-----------------------------------------------------------------------------
--
-- a basic player area for the viewer
--
-----------------------------------------------------------------------------
player_bar=function(d)

	d.maxenergy=300

	if d.player then
			
		d.score=num_to_thousands(d.player.score)
		d.bux=num_to_thousands(d.player.bux)
		
		return replace(get_plate("player_bar"),d)

	end
	
	return replace(get_plate("player_bar_empty"),d)

end

-----------------------------------------------------------------------------
--
-- display a round row, for use in a "table" list of rounds 
--
-----------------------------------------------------------------------------
round_row_header=function(d)

	return replace(get_plate("round_row_header"),d)
end	

round_row_footer=function(d)
	return replace(get_plate("round_row_footer"),d)
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
			
		return replace(get_plate("round_row"),d)
	end
	
	return replace(get_plate("round_row_empty"),d)

end


-----------------------------------------------------------------------------
--
-- display an old round row, for use in a "table" list of rounds 
--
-----------------------------------------------------------------------------
old_round_row_header=function(d)

	return replace(get_plate("old_round_row_header"),d)
end	

old_round_row_footer=function(d)
	return replace(get_plate("old_round_row_footer"),d)
end

old_round_row=function(d)

	local r=d.round
	
	if r then
	
		d.speed=math.floor(60*60 / r.timestep) -- energy per hour
		d.start=os.date("%Y%m%d",r.created) -- 8 digit year-month-day number
		d.remaining=rough_english_duration(r.endtime-d.srv.time).." remaining" -- remaining play time
		if r.endtime-d.srv.time <= 0 then d.remaining="game over man" end
		d.players=r.players
		d.url=d.srv.url_base..r.id
			
		return replace(get_plate("old_round_row"),d)
	end
	
	return replace(get_plate("old_round_row_empty"),d)

end


-----------------------------------------------------------------------------
--
-- display a player row
--
-----------------------------------------------------------------------------
player_row_header=function(d)
	d.random=math.random(1,3)
	return replace(get_plate("player_row_header"),d)
end

player_row_footer=function(d)
	return replace(get_plate("player_row_footer"),d)
end

player_row=function(d)

	if d.player then
	
		d.score=num_to_thousands(d.player.score)
		d.bux=num_to_thousands(d.player.bux)
			
		return replace(get_plate("player_row"),d)
	end
	
	return replace(get_plate("player_row_empty"),d)

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
		
		return replace(get_plate("player_base"),d)
	end
	
	return replace(get_plate("player_base_empty"),d)

end
			
-----------------------------------------------------------------------------
--
-- display player work form
--
-----------------------------------------------------------------------------
player_work_form=function(d)

	for i,v in pairs{1,5,10,20} do
		if v==d.xwork then
			d["check"..v]=" checked=\"true\""
		else
			d["check"..v]=""
		end
	end
	
	for i,v in pairs{0,25,50,75,100} do
		d["set"..v]="$('#hoe_player_work_form_payout').attr('value','"..v.."');$('#hoe_player_work_form_slide').slider('option','value',"..v..");return false"
	end
	
	return replace(get_plate("player_work_form"),d)

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
		d.sbux=replace(get_plate("player_work_result_bux_add"),d)
	end
	
	if d.result.hoes>0 then
		d.one=d.result.hoes
		d.s=""
		if d.one>1 then d.s="s" end
		d.shoes=replace(get_plate("player_work_result_hoes_add"),d)
	elseif d.result.hoes<0 then
		d.one=-d.result.hoes
		d.s=""
		if d.one>1 then d.s="s" end
		d.shoes=replace(get_plate("player_work_result_hoes_sub"),d)
	end

	if d.result.bros>0 then
		d.one=d.result.bros
		d.s=""
		if d.one>1 then d.s="s" end
		d.sbros=replace(get_plate("player_work_result_bros_add"),d)
	end
	
	return replace(get_plate("player_work_result"),d)

end

-----------------------------------------------------------------------------
--
-- suggest an act
--
-----------------------------------------------------------------------------
request_login=function(d)

	d.action="<a href=\"/dumid/login/?continue="..url_esc(d.srv.url).."\">Login</a>"
	
	return replace(get_plate("request_login"),d)

end

-----------------------------------------------------------------------------
--
-- suggest an action
--
-----------------------------------------------------------------------------
request_join=function(d)

	d.action="<a href=\""..d.H.url_base.."do/"..d.act.."\">Join</a>"
	
	return replace(get_plate("request_join"),d)

end

-----------------------------------------------------------------------------
--
-- missing content
--
-----------------------------------------------------------------------------
missing_content=function(d)

	return replace(get_plate("missing_content"),d)

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
local phrase={"Excellent choice, my lord.",
			  "You have good taste, if I may say so.",
			  "Delightful!",
			  "This is my final offer. Take it or leave it.",
			  "Those are all I have. For now.",
			  "One day, my prince will come.",
			  "You need to lay off those snacks. That is my only advice.",
			  "Please do not use disguises to get a better price.",
			  "Stay a while and purchase.",
			  "Good day, sir!",
			  "Leave your name and number and a large sack of bux.",
			  "I see good fortune in my future.",
			  "Tee hee hee. No, these aren't pre-owned.",
			  "Bux only, I do not accept plastics. I'm going green.",
			  "Back again, so soon?",
			  "These are very much in demand, it seems.",
			  "Your purchases please me.",
			  "A wise choice, madam.",
			  "It's not like I have a limited supply of these.",
			  "This is a special price. Just for you.",
			  "Of course I don't hike prices. What are you implying?",
			  "What to buy, what to buy, what to buy.",
			  "It's you again, it seems. Such is my fate.",
			  "One day, I might close shop to go on that fishing trip.",
			  "Hello, it's nice to have you visit.",
			  "I've just had these specially ordered for you.",
			  "Would you like these wrapped up?",
			  "A witch's work is never done. Now, hurry up, I have plenty to do."}
	d.houses_bux=num_to_thousands(d.cost.houses)
	d.bros_bux=num_to_thousands(d.cost.bros)
	d.gloves_bux=num_to_thousands(d.cost.gloves)
	d.sticks_bux=num_to_thousands(d.cost.sticks)
	d.manure_bux=num_to_thousands(d.cost.manure)
	d.random=math.random(1,3)
	d.phrase=phrase[math.random(1,#phrase)]

	return replace(get_plate("player_shop_form"),d)

end

-----------------------------------------------------------------------------
--
-- display player work form
--
-----------------------------------------------------------------------------
player_shop_result=function(d)

	if d.fail then
		d.need=num_to_thousands(-d.result.bux or 0)
		return replace(get_plate("player_shop_result"),d)
	else

		return replace(get_plate("player_shop_result_empty"),d)
	end
end

-----------------------------------------------------------------------------
--
-- display player shop results
--
-----------------------------------------------------------------------------
player_shop_results=function(d)

	return replace(get_plate("player_shop_results"),d)
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
		
			d.form=replace(get_plate("player_profile_form_edit"),d)
		elseif d.fight then
			d.form=replace(get_plate("player_profile_form_fight"),d)
		end
		
		return replace(get_plate("player_profile"),d)

end


-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_header=function(d)
	return replace(get_plate("trade_header"),d)
end
-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_footer=function(d)
	return replace(get_plate("trade_footer"),d)

end

-----------------------------------------------------------------------------
--
-- trade wrap
--
-----------------------------------------------------------------------------
trade_wrap_head=function(d)
	return replace(get_plate("trade_wrap_head"),d)
end
trade_wrap_foot=function(d)
	return replace(get_plate("trade_wrap_foot"),d)
end


trade_row_best=function(d)
d.random=math.random(1,12)
	return replace(get_plate("trade_row_best"),d)
end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_row=function(d)
d.random=math.random(1,12)

	d.part2=replace(get_plate("trade_row_sell"),d)
	d.part1=""

	if not d.best then -- none available	
		d.part1=replace(get_plate("trade_row_none"),d)
	else
		d.part1=replace(get_plate("trade_row_best"),d)
	end

	return replace(get_plate("trade_row_parts"),d)
end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_buy_fail=function(d)

	return replace(get_plate("trade_buy_fail"),d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_buy_fail_self=function(d)

	return replace(get_plate("trade_buy_fail_self"),d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_buy_fail_cost=function(d)

	return replace(get_plate("trade_buy_fail_cost"),d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_buy_fail_energy=function(d)

	return replace(get_plate("trade_buy_fail_energy"),d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_sell_fail_queue=function(d)

	return replace(get_plate("trade_sell_fail_queue"),d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_buy=function(d)

	return replace(get_plate("trade_buy"),d)

end

-----------------------------------------------------------------------------
--
-- trade options
--
-----------------------------------------------------------------------------
trade_sell=function(d)

	return replace(get_plate("trade_sell"),d)

end


-----------------------------------------------------------------------------
--
-- fight
--
-----------------------------------------------------------------------------
fight_header=function(d)
d.random=math.random(1,12)
d.random1=math.random(1,3)

	return replace(get_plate("fight_header"),d)

end
-----------------------------------------------------------------------------
--
-- fight
--
-----------------------------------------------------------------------------
fight_footer=function(d)

	return replace(get_plate("fight_footer"),d)

end
-----------------------------------------------------------------------------
--
-- fight
--
-----------------------------------------------------------------------------
fight_rob_preview=function(d)

	return replace(get_plate("fight_rob_preview"),d)

end

fight_arson_preview=function(d)

	return replace(get_plate("fight_arson_preview"),d)

end

fight_party_preview=function(d)

	return replace(get_plate("fight_party_preview"),d)

end

fight_result=function(d)

	return replace(get_plate("fight_result"),d)

end

-----------------------------------------------------------------------------
--
-- acts
--
-----------------------------------------------------------------------------
profile_acts_header=function(d)

	return replace(get_plate("profile_acts_header"),d)

end
-----------------------------------------------------------------------------
--
-- acts
--
-----------------------------------------------------------------------------
profile_acts_footer=function(d)

	return replace(get_plate("profile_acts_footer"),d)

end
-----------------------------------------------------------------------------
--
-- acts
--
-----------------------------------------------------------------------------
profile_act=function(d)

	d.ago=rough_english_duration(d.srv.time-d.act.created)

	return replace(get_plate("profile_act"),d)

end
