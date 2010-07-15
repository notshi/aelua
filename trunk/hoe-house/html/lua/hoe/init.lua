
local wet_html=require("wetgenes.html")

local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")
local user=users.get_viewer()

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html=require("html")
local players=require("hoe.players")
local rounds=require("hoe.rounds")



local os=os
local math=math
local string=string
local table=table

local ipairs=ipairs
local pairs=pairs
local tostring=tostring
local tonumber=tonumber
local type=type

local footer_data={
	app_name="hoe-house",
	app_link="http://code.google.com/p/aelua/wiki/AppHoeHouse",
}

module("hoe")

-----------------------------------------------------------------------------
--
-- create a main hoe state table
-- this can contain cached round and player info as well as srv
-- so for hoe functions we can pass this around rather than srv directly
--
-----------------------------------------------------------------------------
function create(srv)

	local H={}
	
	H.user=user
	H.srv=srv
	H.slash=srv.url_slash[ srv.url_slash_idx ]
	
	H.put=function(a,b)
		b=b or {}
		b.srv=srv
		b.H=H
		srv.put(wet_html.get(html,a,b))
		b.srv=nil
		b.H=nil
	end
	
	H.arg=function(i) return srv.url_slash[ srv.url_slash_idx + i ]	end
	
	return H

end


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)

	local H=create(srv)
	H.srv.crumbs[#H.srv.crumbs+1]={url="/",title="Hoe House",link="Home",}
	
	local put=H.put
	local roundid=tonumber(H.slash or 0) or 0
	if roundid>0 then -- load a default round from given id
		H.round=rounds.get_id(H,roundid)
	end
	
	if H.round then -- we have a round, let them handle everything
		H.url_base=srv.url_base..H.round.key.id.."/"

		return serv_round(H)
	end
	
-- post handled everything
	
		


	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	
-- ask which round

	local list=rounds.list(H)
	
	for i=1,#list do local v=list[i]
		put("round_row",{round=v.cache})		
	end
	
	put("about",{})	
	
	put("footer",footer_data)
	
end



-----------------------------------------------------------------------------
--
-- basic serv when we are dealing with an existing round
--
-----------------------------------------------------------------------------
function serv_round(H)

local put=H.put
	
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base,title="Round "..H.round.key.id,link="Round "..H.round.key.id,}
	
	H.cmd_request=nil

	H.user_data_name=H.srv.flavour.."_hoe_"..H.round.key.id -- unique data name for this round

	if user then -- we have a user
	
		local user_data=user.cache[H.user_data_name]

		if user_data then -- we already have data, so use it
			H.player=players.get_id(H,user_data.player_id)
		end
		
		if not H.player then -- no player in this round
		
			if H.round.cache.state=="active" then -- viewing an active round so sugest a join
			
				H.cmd_request="join"
				
			end
		end
	
	else -- no user so suggest they login
	
			H.cmd_request="login"
	
	end
	
	local cmd=H.arg(1)

	if cmd=="do" then -- perform a basic action with mild security
	
		local id=H.arg(2)
		local dat=users.get_act(user,id)
		
		if dat then
		
			if dat.check==H.user_data_name then -- good data
			
				if dat.cmd=="join" then -- join this round
			
					players.join(H,user)
					H.srv.redirect(H.url_base) -- simplest just to redirect at this point
					return true

				end
			end
		end
	end
	
	

-- functions for each special command	
	local cmds={
		list=	serv_round_list,
		work=	serv_round_work,
		shop=	serv_round_shop,
		profile=serv_round_profile,
		fight=	serv_round_fight,
		trade=	serv_round_trade,
	}
	local f=cmds[ string.lower(cmd or "") ]
	if f then return f(H) end

-- or display base menu

	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	put("player_bar",{player=H.player and H.player.cache})
	
	if H.cmd_request=="join" then
		put("request_join",{act=users.put_act(user,{cmd="join",check=H.user_data_name})})
	elseif H.cmd_request=="login" then
		put("request_login",{})
	end
	
	put("hoe_menu_items",{})
	
	put("footer",footer_data)
	
end


-----------------------------------------------------------------------------
--
-- list users
--
-----------------------------------------------------------------------------
function serv_round_list(H)

local put=H.put

	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."list/",title="list",link="list",}

	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	put("player_bar",{player=H.player and H.player.cache})
		
	put("player_row_header",{})
	local list=players.list(H)
	for i=1,#list do local v=list[i]
		put("player_row",{player=v.cache})
	end
	put("player_row_footer",{})
		
	put("footer",footer_data)
	
end



-----------------------------------------------------------------------------
--
-- work hoes
--
-----------------------------------------------------------------------------
function serv_round_work(H)

local put=H.put

	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."work/",title="work",link="work",}

	local result
	local payout
	local xwork=1
	if H.player and H.srv.posts.payout then
		payout=math.floor(tonumber(H.srv.posts.payout))
		if payout<0 then payout=0 end
		if payout>100 then payout=100 end
		
		result={}
		result.energy=0
		result.hoes=0
		result.bros=0
		result.bux=0
		
		local total=0
		
		local p=H.player.cache
		
		local rep=1
		if H.srv.posts.x then
			rep=tonumber(H.srv.posts.x)
			rep=math.floor(rep)
		end
		if rep>p.energy then rep=p.energy end -- do not try and work too many times
		if rep<1 then rep=1 end
		if rep>10 then rep=10 end
		xwork=rep
		for i=1,rep do -- repeat a few times, yes this makes for bad integration...
			result.energy=result.energy-1
					
			local houses=tonumber(p.houses)
			local hoes=tonumber(p.hoes)
			local crowd=hoes/(houses*50) -- how much space we have for hoes, 0 is empty and 1 is full
			local pay=payout/100
			local mypay=1-pay
			
			local gain=(1-(crowd/2)) -- 1.0 when empty , 0.5 when full , and 0.0 when bursting
			if gain<0 then gain=0 end
			gain = gain * pay * 1.0 -- also adjust by payout 
			
			if math.random() < gain then -- we gain a new hoe
				result.hoes=result.hoes+1
				if math.random() < gain then -- we also gain a new bro
					result.bros=result.bros+1
				end
			end
			
			local loss=(crowd) * mypay
			if math.random() < loss then -- we lose a hoe
				result.hoes=result.hoes-1
			end
			
			local tbux=math.floor((50 + 450*math.random()) * hoes) -- how much is earned
			local bux=math.floor(tbux * mypay) -- how much we keep
			result.bux=result.bux+bux
			total=total+tbux
		end
		
		local r=players.update_add(H,H.player,result)
		if r then
			H.player=r
			result.total_bux=total
		else
			result=nil -- failed, no energy?
		end
	end

	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	put("player_bar",{player=H.player and H.player.cache})
	
	if result then
		put("player_work_result",{result=result,xwork=xwork or 1})
	end
	
	if H.player then
		put("player_work_form",{payout=payout or 50,xwork=xwork or 1})
	else
		put("player_needed",{})
	end
	
	put("footer",footer_data)
	
end

-----------------------------------------------------------------------------
--
-- shop
--
-----------------------------------------------------------------------------
function serv_round_shop(H)

	local put=H.put
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."shop/",title="shop",link="shop",}
	
	local cost={}
	local function workout_cost()
		cost.houses=50000 * H.player.cache.houses
		cost.bros=1000 + (10 * H.player.cache.bros)
		cost.gloves=1
		cost.sticks=10
		cost.manure=100
	end
	workout_cost()
	
	local result
	if H.player and H.srv.posts.houses then	-- attempt to buy
	
		local by={}
		by.houses=tonumber(H.srv.posts.houses)
		by.bros=tonumber(H.srv.posts.bros)
		by.gloves=tonumber(H.srv.posts.gloves)
		by.sticks=tonumber(H.srv.posts.sticks)
		by.manure=tonumber(H.srv.posts.manure)
		for i,v in pairs(by) do
			v=math.floor(v)
			if v<0 then v=0 end
			by[i]=v
		end
		if by.houses>1 then by.houses=1 end -- may only buy one house at a time
		by.bux=0
		for i,v in pairs(cost) do
			if by[i] then
				by.bux=by.bux-(v*by[i]) -- cost to purchase
			end
		end
		if H.player.cache.bux + by.bux < 0 then -- not enough cash
			result=by
			result.fail="bux"
		else
			local r=players.update_add(H,H.player,by)
			if r then
				H.player=r
				workout_cost()
				result=by
			else
				result=nil -- failed, but do not report
			end
		end
	end
	
	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	put("player_bar",{player=H.player and H.player.cache})
	
	if result then
		put("player_shop_result",{result=result})
	end
	
	if H.player then
		put("player_shop_form",{cost=cost})
	else
		put("player_needed",{})
	end
		
	put("footer",footer_data)

end

-----------------------------------------------------------------------------
--
-- profile
--
-----------------------------------------------------------------------------
function serv_round_profile(H)

	local put=H.put
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."profile/",title="profile",link="profile",}
	
	if H.player and (H.srv.posts.name or H.srv.posts.shout) then
		local by={}
		
		if H.srv.posts.do_name and H.srv.posts.name then
			local s=H.srv.posts.name
			if string.len(s) > 20 then s=string.sub(s,1,20) end
			by.name=wet_html.esc(s)
		end

		if H.srv.posts.do_shout and H.srv.posts.shout then
			local s=H.srv.posts.shout		
			if string.len(s) > 100 then s=string.sub(s,1,100) end		
			by.shout=wet_html.esc(s)
		end
		
		local r=players.update_add(H,H.player,by)
		if r then
			H.player=r
		end
	end

	local view=tonumber(H.arg(2) or 0) or 0
	if view<=0 then view=nil end
	if view then
		view=players.get_id(H,view)
		if view then
			if view.cache.round_id~=H.round.key.id then view=nil end -- check that player belongs to this round
		end
	end

	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	put("player_bar",{player=H.player and H.player.cache})
	
	if view and view.cache then 
		put("player_profile",{player=view.cache,edit=false,fight=true})
	else
		put("player_profile",{player=H.player and H.player.cache,edit=true})
	end
	
	put("footer",footer_data)

end

-----------------------------------------------------------------------------
--
-- fight
--
-----------------------------------------------------------------------------
function serv_round_fight(H)

	local put=H.put
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."fight/",title="fight",link="fight",}

	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	put("player_bar",{player=H.player and H.player.cache})
	
	put("missing_content",{})
		
	put("footer",footer_data)

end


-----------------------------------------------------------------------------
--
-- trade
--
-----------------------------------------------------------------------------
function serv_round_trade(H)

	local put=H.put
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."trade/",title="trade",link="trade",}

	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	put("player_bar",{player=H.player and H.player.cache})
	
	put("missing_content",{})
		
	put("footer",footer_data)

end

