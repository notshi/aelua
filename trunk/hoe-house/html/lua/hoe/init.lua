
local wet_html=require("wetgenes.html")

local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local Json=require("Json")

-- require all the module sub parts
local html=require("html")
local players=require("hoe.players")
local rounds=require("hoe.rounds")
local trades=require("hoe.trades")



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

local sess,user=users.get_viewer_session(srv)

	local H={}
	
	H.user=user
	H.sess=sess
	H.srv=srv
	H.slash=srv.url_slash[ srv.url_slash_idx ]
		
	H.get=function(a,b) -- get some html
		b=b or {}
		b.srv=srv
		b.H=H
		local r=wet_html.get(html,a,b)
		b.srv=nil
		b.H=nil
		return r
	end
	
	H.put=function(a,b) -- put some html
		srv.put(H.get(a,b))
	end
	
	H.arg=function(i) return srv.url_slash[ srv.url_slash_idx + i ]	end -- get an arg from the url
	
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

		H.energy_frac=(H.srv.time/H.round.cache.timestep)
		H.energy_frac=H.energy_frac-math.floor(H.energy_frac) -- fractional amount of energy we have
		H.energy_step=H.round.cache.timestep

		return serv_round(H)
	end
	
-- post handled everything
	
		


	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{})
	
-- ask which round

	local list=rounds.list(H)
	put("round_row_header",{})
	for i=1,#list do local v=list[i]
		put("round_row",{round=v.cache})		
	end
	put("round_row_footer",{})
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

	if H.user then -- we have a user
	
		local user_data=H.user.cache[H.user_data_name]

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
		local dat=users.get_act(H.user,id)
		
		if dat then
		
			if dat.check==H.user_data_name then -- good data
			
				if dat.cmd=="join" then -- join this round
			
					players.join(H,H.user)
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
	put("user_bar",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	if H.cmd_request=="join" then
		put("request_join",{act=users.put_act(H.user,{cmd="join",check=H.user_data_name})})
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
	put("user_bar",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	local page={} -- this sort of dumb paging should be fine for now? bad for appengine though
	page.show=0
	page.size=50
	page.next=page.size
	page.prev=0
	
	if H.srv.gets.show then
		page.show=math.floor( tonumber(H.srv.gets.off) or 0)
	end
	if page.show<0 then page.show=0 end	-- no negative offsets going in
	
	local list=players.list(H,{limit=page.size,offset=page.show})
	
	page.next=page.show+page.size
	page.prev=page.show-page.size
	if page.prev<0 then page.prev=0 end -- and prev does not go below 0 either	
	if #list < lim then page.next=0 end -- looks last page so set to 0
	
	put("player_row_header",{url=H.srv.url,page=page})
	for i=1,#list do local v=list[i]
		put("player_row",{player=v.cache,idx=i+page.show})
	end
	put("player_row_footer",{url=H.srv.url,page=page})
		
	put("footer",footer_data)
	
end



-----------------------------------------------------------------------------
--
-- work hoes
--
-----------------------------------------------------------------------------
function serv_round_work(H)

local put=H.put

	local url=H.url_base.."work"
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."work/",title="work",link="work",}
	
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if H.srv.headers.Referer and string.sub(H.srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(H.srv.posts) do
			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end

	local result
	local payout
	local xwork=1
	
	if H.player and posts.payout then
		payout=math.floor(tonumber(posts.payout) or 0)
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
		if posts.x then
			rep=tonumber(posts.x)
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
	put("user_bar",{})
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
	local url=H.url_base.."shop"
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."shop/",title="shop",link="shop",}
		
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if H.srv.headers.Referer and string.sub(H.srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(H.srv.posts) do
			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	
	local cost={}
		
	if H.player then -- must be logged in
	
		local function workout_cost()
			cost.houses=50000 * H.player.cache.houses
			cost.bros=1000 + (10 * H.player.cache.bros)
			cost.gloves=1
			cost.sticks=10
			cost.manure=100
		end
		workout_cost()
		
		local result
		if H.player and posts.houses then	-- attempt to buy
		
			local by={}
			by.houses=tonumber(posts.houses)
			by.bros=tonumber(posts.bros)
			by.gloves=tonumber(posts.gloves)
			by.sticks=tonumber(posts.sticks)
			by.manure=tonumber(posts.manure)
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
		
	end
	
	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{})
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
	local url=H.url_base.."profile"
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."profile/",title="profile",link="profile",}
	
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if H.srv.headers.Referer and string.sub(H.srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(H.srv.posts) do
			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	
	if H.player and (posts.name or posts.shout) then
		local by={}
		
		if posts.do_name and posts.name then
			local s=posts.name
			if string.len(s) > 20 then s=string.sub(s,1,20) end
			by.name=wet_html.esc(s)
		end

		if posts.do_shout and posts.shout then
			local s=posts.shout		
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
	put("user_bar",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	if view and view.cache then 
		put("player_profile",{player=view.cache,edit=false,fight=true})
	elseif H.player then
		put("player_profile",{player=H.player.cache,edit=true})
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
	put("user_bar",{})
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

	-- these are the allowed trades , the first name is offered
	-- and the second name is the payment type
	local valid_trades={
			{"houses","hoes"},
			{"hoes","bros"},
			{"bros","bux"},
		}

	local put,get=H.put,H.get
	local url=H.url_base.."trade"
	H.srv.crumbs[#H.srv.crumbs+1]={url=H.url_base.."trade/",title="trade",link="trade",}
	
	local posts={} -- remove any gunk from the posts input
	-- check if this post probably came from this page before allowing post params
	if H.srv.headers.Referer and string.sub(H.srv.headers.Referer,1,string.len(url))==url then
		for i,v in pairs(H.srv.posts) do
			posts[i]=string.gsub(v,"[^%w%p ]","") -- sensible characters only please
		end
	end
	
	local trade -- offering [1] want to be paid in [2], use string names for items
	local results="" -- any extra result html
	
	if posts.trade then -- we want to trade
	
		if posts.trade~="" then
			local aa=str_split("4",posts.trade)
			if aa[1] and aa[2] then -- possible
				for i=1,#valid_trades do local v=valid_trades[i]
					if v[1]==aa[1] and v[2]==aa[2] then -- found valid trade
						trade=v
						break
					end
				end
			end
		end
		
		if trade then -- a valid trade, lets give it a go
		
			local key=math.floor(tonumber(posts.key or 0) or 0)
			local count=math.floor(tonumber(posts.count or 0) or 0)
			local cost=math.floor(tonumber(posts.cost or 0) or 0)
			
			if count<0 then count=0 end
			if cost <0 then cost =0 end
			
			if count>1000000 then count=1000000 end -- best to also have a max, 1 million? sure why not?
			if cost >1000000 then cost =1000000 end
			
			if posts.cmd=="buy" then
			
			
				local best=trades.find_cheapest(H,{offer=trade[1],seek=trade[2]}) -- get the best trade
				
				if (not best) or best.cache.id~=key then -- fail if best is not the one we wanted...
				
					results=results..get("trade_buy_fail") -- failed to buy
					
				else
				
					if H.player.cache[ trade[2] ] >= best.cache.price then -- must have price available
				
						local claim_trade=function()
							return trades.update(H,best,function(H,p)
								if p.buyer==0 then p.buyer=H.player.cache.id return true end
							end)
						end
						local undo_trade=function()
							return trades.update(H,best,function(H,p)
								if p.buyer==H.player.cache.id then p.buyer=0 return true end
							end)
						end
						
						if claim_trade() then -- first we claim the trade
						
							local f=function(H,p)
								if p[ trade[2] ]<(best.cache.price) then -- must have goods available
									return false
								end
								if trade[2]=="houses" then -- must always own at least one house...
									if p[ trade[2] ]<=(count) then
										return false
									end
								end
								p[ trade[1] ]=p[ trade[1] ]+(best.cache.count) -- give goods right now
								p[ trade[2] ]=p[ trade[2] ]-(best.cache.price) -- remove price right now
								return true
							end
			
							if players.update(H,H.player,f) then -- goods where removed, now give price to trader
							
								local adjust={}
								adjust[ trade[2] ]=best.cache.price
								players.update_add(H,best.cache.player,adjust) -- hand over the price
								
								results=results..get("trade_buy",{trade=best.cache}) -- finally say we bought stuff				
								
								H.player=players.get(H,H.player) -- get updated self
							else
								undo_trade() -- release the trade
								results=results..get("trade_buy_fail_cost") -- failed to buy					
							end
							
						end
					else
						results=results..get("trade_buy_fail_cost") -- failed to buy					
					end
				end

			
			elseif posts.cmd=="sell" and count>0 and cost>0 then -- must sell something
			
				if H.player.cache[ trade[1] ] >= count then -- must have goods available
				
					local f=function(H,p)
						if p[ trade[1] ]<(count) then -- must have goods available
							return false
						end
						if trade[1]=="houses" then -- must always own at least one house...
							if p[ trade[1] ]<=(count) then
								return false
							end
						end
						p[ trade[1] ]=p[ trade[1] ]-(count) -- remove goods right now
						return true
					end
	
					if players.update(H,H.player,f) then -- goods where removed
					
						local ent=trades.create(H)
						ent.cache.player=H.player.cache.id
						ent.cache.offer=trade[1]
						ent.cache.seek=trade[2]
						ent.cache.count=count
						ent.cache.cost=cost
						
						trades.check(H,ent)		-- this will calculate the total price
						
						trades.put(H,ent)		-- create trade in database
						
						trades.fix_memcache(H,trades.what_memcache(H,ent)) -- update cache values
						
						results=results..get("trade_sell",{trade=ent.cache}) -- we added a trade
						
						H.player=players.get(H,H.player) -- get updated self
					end
				
				end
			
			end
			
		end
		
	end
	
	
	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{})
	put("player_bar",{player=H.player and H.player.cache})
	
	put(results)
	
	put("trade_header",{trades=trades})
	for i=1,#valid_trades do local v=valid_trades[i]
		local trade={}
		trade.offer=v[1]
		trade.seek=v[2]
		trade.best=trades.find_cheapest(H,trade)
		put("trade_row",{trade=trade,best=trade.best and trade.best.cache,url=url})
	end
	put("trade_footer",{trades=trades})
	
	put("footer",footer_data)

end
