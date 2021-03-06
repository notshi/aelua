
-- a monter or player or any other character, really just a slightly more active item
-- these are items that need to update as time passes

local _G=_G

local win=win

local table=table
local ipairs=ipairs
local string=string
local math=math
local os=os

local pairs=pairs
local setfenv=setfenv
local unpack=unpack
local require=require




module(...)
local hack_item_data=require("hack.itemdata")

function ascii(a) return string.byte(a,1) end

function get(n,f)

	f=f or 0
	
	local it={}
	
	local d=hack_item_data[n]
	
	for i,v in pairs(d[1]) do it[i]=v end
	for i,v in pairs(d[2]) do it[i]=it[i] + math.floor(v*f) end
	
	return it

end


ant_corpse={{
	class="corpse",
	flavour="ant",
	asc=ascii("%"),
	weight=1,
	desc="a corpse of an ant",
},{
}}

blob_corpse={{
	class="corpse",
	flavour="blob",
	asc=ascii("%"),
	weight=1,
	desc="a corpse of a blob",
},{
}}

