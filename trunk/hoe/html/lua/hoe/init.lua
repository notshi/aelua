
local wet_html=require("wetgenes.html")

local dat=require("wetgenes.aelua.data")

local user=require("wetgenes.aelua.user")

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
	
	H.srv=srv
	H.slash=srv.url_slash[ srv.url_slash_idx ]
	
	H.put=function(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end
	
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

local function put(a,b)
	b=b or {}
	b.srv=srv
	srv.put(wet_html.get(html,a,b))
end

	local H=create(srv)
	local roundid=tonumber(H.slash or 0) or 0
	if roundid>0 then -- load a default round from given id
		H.round=rounds.load_id(H,roundid)
	end
	
	if H.round then -- we have a round
		put(tostring(H.round),{})
		return
	end
	
	if post(H) then return end -- post handled everything
	
		


	srv.set_mimetype("text/html")
	put("header",{title="Hoe House - "})
	put("home_bar",{})
	put("user_bar",{})
	
-- ask which round

	local list=rounds.list(H)
	
	put("<br/>",{})
	
	for i=1,#list do local v=list[i]
	
		put("<br/>",{})
		put("LIST : "..i.."<br/>",{})
		put("DATE : "..os.date("%c",v.created).."<br/>" )
		put("ID : "..(v.id).."<br/>" )
		put("STEP : "..(v.timestep).."<br/>" )
		
		local url=srv.url_base..v.id.."/"
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

