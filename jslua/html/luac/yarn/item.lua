
-- a single item

local _G=_G


local table=table
local ipairs=ipairs
local string=string
local math=math
local os=os

local setfenv=setfenv
local unpack=unpack
local require=require
local setmetatable=setmetatable



module(...)
local yarn_attr=require("yarn.attr")


function create(t,_level)

	
local d={}
setfenv(1,d)

	attr=yarn_attr.create(t)
	metatable={__index=attr}
	setmetatable(d,metatable)

	level=_level or t.level
	class=t.class
	
	cell_fx=t.cell_fx or {}
	
	time_passed=level.time_passed

	function del()
		if cell then -- remove link from old cell
			cell.items[d]=nil
		end
	end

	function set_cell(c)
	
		if cell then -- remove link from old cell, only one char per cell
			cell.items[d]=nil
		end
		
		cell=c
		cell.items[d]=true
		
	end
	
	function asc()
		return attr.asc
	end
	
	function view_text()
		return "You see "..(attr.desc or "something").."."
	end

	return d
	
end

