
-- a monster or player or any other character, really just a slightly more active item
-- these are items that need to update as time passes or items where only 1 may exist
-- in a cell at once. So it could just be a wardrobe.

local _G=_G


local table=table
local ipairs=ipairs
local string=string
local math=math
local os=os

local setfenv=setfenv
local unpack=unpack
local require=require



module(...)
local yarn_attr=require("yarn.attr")
local yarn_fight=require("yarn.charfight")


local a_at=string.byte("@",1)
local a_a=string.byte("a",1)


function create(_t,_level)

	
local d={}
setfenv(1,d)

	t=_t
	level=_level or t.level
	class=t.class
	
	time_passed=level.time_passed

	attr=yarn_attr.create(t)
	
	function del()
		if cell then -- remove link from old cell
			cell.char=nil
		end
	end
	
	function set_cell(c)
	
		if cell then -- remove link from old cell, only one char per cell
			cell.char=nil
		end
		
		cell=c
		cell.char=d
		
		if attr.can.make_room_visible then -- this char makes the room visible (ie its the player)
			for i,v in cell.neighboursplus() do -- apply to neighbours and self
				if v.room and ( not v.room.attr.get.visible() ) then -- if room is not visible
					v.room.set_visible(true)
				end
			end
		end
		
	end
	
	function move(vx,vy)
		local x=cell.xp+vx
		local y=cell.yp+vy
		local c=level.get_cell(x,y)
		if c and c.name=="floor" then -- its a cell we can move into
			if c.char then -- interact with another char?
				if c.char.attr.can.fight then
					yarn_fight.hit(d,c.char)
					return 1
				end
			else -- just move
				set_cell(c)
				return 1 -- time taken to move
			end
		end
		return 0
	end

	function die()
		local p=level.new_item( class.."_corpse" )
		p.set_cell( cell )

		level.del_item(d)
	end
	
	function asc()
		return attr.asc
	end
	
	function view_text()
		return "You see "..(attr.desc or "something").."."
	end

	function update()
	
		if attr.can.roam=="random" then
		
			if 	time_passed<level.time_passed then
		
				local vs={ {1,0} , {-1,0} , {0,1} , {0,-1} }
				
				vs=vs[level.rand(1,4)]
				
				move(vs[1],vs[2])
				
				time_passed=time_passed+1
			end
			
		end
	end
	
	return d
	
end

