
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
local html=require("hoe.html")
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
	local put=H.put
	local roundid=tonumber(H.slash or 0) or 0
	if roundid>0 then -- load a default round from given id
		H.round=rounds.get_id(H,roundid)
	end
	
	if H.round then -- we have a round, let them handle everything
		H.url_base=srv.url_base..H.round.key.id.."/"

		return serv_round(H)
	end
	
	if post(H) then return end -- post handled everything
	
		


	H.srv.set_mimetype("text/html")
	put("header",{title="Hoe House - "})
	put("home_bar",{})
	put("user_bar",{user=user})
	
-- ask which round

	local list=rounds.list(H)
	
	put("<br/>",{})
	
	for i=1,#list do local v=list[i]
	
		put("<br/>",{})
		put("DATE : "..os.date("%c",v.cache.created).."<br/>" )
		put("ID : "..(v.key.id).."<br/>" )
		put("STEP : "..(v.cache.timestep).."<br/>" )
		
		local url=srv.url_base..v.key.id.."/"
		put("Link : <a href=\""..url.."\">"..url.."</a><br/>" )
		put("<br/>",{})
		
	end
	
	put("about",{})	
	
	put("footer",{})
	
end


-----------------------------------------------------------------------------
--
-- the post function, looks for post params and handles them
--
-----------------------------------------------------------------------------
function post(H)

	return false

end

-----------------------------------------------------------------------------
--
-- the post function, looks for post params and handles them
--
-----------------------------------------------------------------------------
function post_round(H)
local put=H.put
local cmd=H.arg(1)

	if cmd=="do" then
	
		local id=H.arg(2)
		local dat=users.get_act(user,id)
		
		if dat then
		
			if dat.check==H.user_data_name then -- good data
			
				if dat.cmd=="join" then -- join this round
			
					players.join(H,user)

--					put(tostring(id))
--					put(tostring(dat))
					H.srv.redirect(H.url_base)
					return true

				end
			end
		end
	end
	
	return false

end

-----------------------------------------------------------------------------
--
-- basic serv when we are dealing with an existing round
--
-----------------------------------------------------------------------------
function serv_round(H)

local put=H.put
	
local request=nil

	H.user_data_name=H.srv.flavour.."_hoe_"..H.round.key.id -- unique data name for this round

	if user then -- we have a user
	
		local user_data=user.cache[H.user_data_name]

		if user_data then -- we already have data, so use it
			H.player=players.get_id(H,user_data.player_id)
		end
		
		if not H.player then -- no player in this round
		
			if H.round.cache.state=="active" then -- viewing an active round so sugest a join
			
				request="join"
				
			end
		end
	
	else -- no user so suggest they login
	
			request="login"
	
	end
	
	if post_round(H) then return end -- post handled everything

	
	H.srv.set_mimetype("text/html")
	put("header",{title="Hoe House - Round "..H.round.cache.id})
	put("home_bar",{})
	put("user_bar",{user=user})
	
	if request=="join" then
		put("request_join",{act=users.put_act(user,{cmd="join",check=H.user_data_name})})
	elseif request=="login" then
		put("request_login",{})
	end
	
	put("listing players <br/>",{})
	local list=players.list(H)
	for i=1,#list do local v=list[i]
		put(tostring(v.key.id).." "..tostring(v.cache.name).."<br/>",{})
	end
		
	put("footer",{})
	
end
