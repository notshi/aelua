
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

for i,v in pairs(package.loaded) do
	print(i,v)
end

print("loading hack.char_data "..(...))

module("...")
print(_M)
print(package.loaded[(...)])
package.loaded[(...)]=_M -- I need this WTF?
local hack_char_data=_M or require("hack.char_data")

function ascii(a) return string.byte(a,1) end

function get(n,f)

	f=f or 0
	
	local it={}
	
	local d=hack_char_data[n]
	
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
	
	cell_fx=
	{
		room_visible=true,
	}
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
	
},{
	score=10,
	hp=10,
	dam_min=2,
	dam_max=2,
	def_add=-1,
	def_mul=0,
}}


