
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
local tostring=tostring
local tonumber=tonumber
local type=type

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
	
	put("footer",{})
	
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
		list=serv_round_list,
		work=serv_round_work,
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
	
--[[
	put("<br/>Basic menu <br/><br/>",{})
	
	local menu={
		{name="work",    url=H.url_base.."work/",    desc="Work to gain bux, hoes and bros."},
		{name="shop",    url=H.url_base.."shop/",    desc="Buy what you need."},
		{name="profile", url=H.url_base.."profile/", desc="View and change how the others see you."},
		{name="list",    url=H.url_base.."list/",    desc="View the leaderboards."},
		{name="fight",   url=H.url_base.."fight/",   desc="Attack the others for fun and profit."},
		{name="trade",   url=H.url_base.."trade/",   desc="Trade with the others."},
	}
	for i=1,#menu do local v=menu[i]
--		put("hoe_menu_item",v)
	end
]]
	put("hoe_menu_items",v)	
	put("footer",{})
	
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
		
	put("<br/>listing players <br/><br/>",{})
	local list=players.list(H)
	for i=1,#list do local v=list[i]
		put("player_row",{player=v.cache})
	end
		
	put("footer",{})
	
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
	if H.srv.posts.payout then
		payout=math.floor(tonumber(H.srv.posts.payout))
		if payout<0 then payout=0 end
		if payout>100 then payout=100 end
		
		result={}
		result.energy=-1
		result.hoes=0
		result.bros=0
		result.bux=0
				
		local p=H.player.cache
		local houses=tonumber(p.houses)
		local hoes=tonumber(p.hoes)
		local crowd=hoes/(houses*50) -- how much space we have for hoes, 0 is empty and 1 is full
		local pay=payout/100
		local mypay=1-pay
		
		local gain=(1-(crowd/2))
		if gain<0 then gain=0 end
		gain = gain * pay * 1.0
		
		if math.random() < gain then -- we gain a new hoe
			result.hoes=result.hoes+1
			if math.random() < gain then -- we also gain a new bro
				result.bros=result.bros+1
			end
		end
		
		local loss=(crowd/2) - pay
		if math.random() < loss then -- we lose a hoe
			result.hoes=result.hoes-1
		end
		
		local bux=math.floor((500 + 1500*math.random()) * hoes * mypay)
		result.bux=result.bux+bux
		
		local r=players.adjust(H,H.player,result)
		if r then H.player=r else result=nil end
	end

	H.srv.set_mimetype("text/html")
	put("header",{})
	put("home_bar",{})
	put("user_bar",{user=user})
	put("player_bar",{player=H.player and H.player.cache})
	
	if result then
		put("player_work_result",{result=result})
	end
	
	put("player_work_form",{payout=payout or 50})
		
	put("footer",{})
	
end



