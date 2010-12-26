
-- a monter or player or any other character, really just a slightly more active item
-- these are items that need to update as time passes

local _G=_G


local table=table
local ipairs=ipairs
local string=string
local math=math
local os=os
local package=package

local pairs=pairs
local setfenv=setfenv
local unpack=unpack
local require=require
local print=print
local tostring=tostring
local exit=exit

module(...)
local attrdata=require(...)

function ascii(a) return string.byte(a,1) end

function get(n,f)

	f=f or 0
	
	local it={}
	
	local d=yarn_char_data[n]
	
	for i,v in pairs(d[1]) do it[i]=v end
	for i,v in pairs(d[2]) do it[i]=it[i] + math.floor(v*f) end
	
	return it

end

player={{
	class="player",
	asc=ascii("@"),
	desc="a human",
	hp=10,
	score=0,
	
	wheel=0,
	dam_min=20,
	dam_max=20,
	def_add=0,
	def_mul=1,
	
	can=
	{
		fight=true,
		make_room_visible=true,
	},
	
},{
}}

stairs_up={{
	class="stairs",
	update="none",
	asc=ascii(">"),
	desc="some stairs up",
	
},{
}}

stairs_down={{
	class="stairs",
	update="none",
	asc=ascii("<"),
	desc="some stairs down",
	
},{
}}

ant={{
	class="ant",
	asc=ascii("a"),
	desc="an ant",
	score=2,
	hp=2,
	
	wheel=0,
	dam_min=1,
	dam_max=2,
	def_add=0,
	def_mul=1,
	
	can=
	{
		fight=true,
		roam="random",
	},
	
},{
	score=2,
	hp=2,
	dam_min=0,
	dam_max=1,
	def_add=-1,
	def_mul=0,
}}


blob={{
	class="blob",
	asc=ascii("b"),
	desc="a blob",
	score=10,
	hp=10,
	
	wheel=0,
	dam_min=2,
	dam_max=4,
	def_add=0,
	def_mul=0.75,
	
	can=
	{
		fight=true,
		roam="random",
	},
	
},{
	score=10,
	hp=10,
	dam_min=2,
	dam_max=2,
	def_add=-1,
	def_mul=0,
}}



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


