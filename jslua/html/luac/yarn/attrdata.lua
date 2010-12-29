
-- data to fill up attr with, this is the main game item/monster/logic content

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

	if not dd[n] then return nil end -- no data

	f=f or 0
	
	local it={}
	
	local d=dd[n] -- get base
	
	for i,v in pairs(d) do it[i]=v end -- copy 1 deep only
	for i,v in pairs(d.level or {} ) do it[i]=(it[i] or 0)+ math.floor(v*f) end
	it.level=nil
	
	return it

end

dd={

{
	name="player",
	form="char",
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
		operate=true,
	},
	
},

{
	name="stairs_up",
	form="char",
	class="stairs",
	asc=ascii(">"),
	desc="some stairs up",
	
},

{
	name="stairs_down",
	form="char",
	class="stairs",
	asc=ascii("<"),
	desc="some stairs down",
	
},

{
	name="cryo_bed",
	form="char",
	class="story",
	asc=ascii("="),
	desc="your cryo generic capsule",
	
	open=true,
	
	can=
	{
		use="menu",
	},
	
	call=
	{
		acts=function(it,by)
			return {"read welcome","look","open","close"}
		end,
		
		look=function(it,by)
			it.level.up.menu.show_text(it.desc,"your cryo generic capsule is ".. (it.open and "open" or "closed") )
		end,
		open=function(it,by)
			it.attr.open=true
			it.call.look(it,by)
		end,
		close=function(it,by)
			it.attr.open=false
			it.call.look(it,by)
		end,
		
		["read welcome"]=function(it,by)
			it.level.up.menu.show_text("Welcome to YARN, where an @ is you",
[[
Press the CURSOR keys to move up/down/left/right.

Press SPACE bar for a menu or to select a menu items.

If you are standing near anything interesting press SPACE bar to interact with it.

Press SPACE to continue.
]])
		end,
		
	},
},

{
	name="cryo_door",
	form="char",
	class="story",
	asc=ascii("|"),
	desc="your cryo generic door",
	
	open=false,
	
	can=
	{
		use="menu",
	},
	
	call=
	{
		acts=function(it,by)
			return {"look","open","close"}
		end,
		
		look=function(it,by)
			it.level.up.menu.show_text(it.desc,"your cryo generic door is ".. (it.open and "open" or "closed") )
		end,
		open=function(it,by)
			it.attr.open=true
			it.attr.form="item"
			it.attr.asc=ascii("/"),
			it.call.look(it,by)
		end,
		close=function(it,by)
			it.attr.open=false
			it.attr.form="char"
			it.attr.asc=ascii("|"),
			it.call.look(it,by)
		end,
	},
},


{
	name="ant",
	form="char",
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
	
	level={
		score=2,
		hp=2,
		dam_min=0,
		dam_max=1,
		def_add=-1,
		def_mul=0,
		},
},


{
	name="blob",
	form="char",
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
	
	level={
		score=10,
		hp=10,
		dam_min=2,
		dam_max=2,
		def_add=-1,
		def_mul=0,
		},
},



{
	name="ant_corpse",
	form="item",
	class="corpse",
	flavour="ant",
	asc=ascii("%"),
	weight=1,
	desc="a corpse of an ant",
},


{
	name="blob_corpse",
	form="item",
	class="corpse",
	flavour="blob",
	asc=ascii("%"),
	weight=1,
	desc="a corpse of a blob",
},

}

-- swing data both ways
for i,v in ipairs(dd) do

	dd[ v.name ] = v -- look up by name
	v.id=i -- every data gets a unique id

end



