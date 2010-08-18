
local wet_html=require("wetgenes.html")

local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local hoe     = require("hoe")
local html    = require("hoe.html")
local rounds  = require("hoe.rounds")
local players = require("hoe.players")



local math=math
local string=string
local table=table

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type

-- console helper commands

module("hoe.con")


function help()
	return
[[
available console helper functions in hoe.con.* are :
help(H)        -- return this text
list_rounds(H) -- return listing of active rounds
make_round(H,t)  -- create a new round for playtesting
]]
end


function list_rounds(H)
	local r={}
	local put=function(s) r[#r+1]=tostring(s) end

	local list=rounds.list(H)	
	for i=1,#list do local v=list[i]
	
		put("LIST : "..i)
		
	end

	return table.concat(r,"\n")
end


function make_round(H,timestep)

	local r=rounds.create(H)
	r.cache.timestep=timestep or 1
	r.cache.endtime=H.srv.time+(r.cache.timestep*4032) -- default game end
	rounds.put(H,r)
end
