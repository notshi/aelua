
-- shared attributes, across cells, items and chars
-- we metamap .attr in these tables so cell.get gets attributes

local _G=_G

local table=table
local pairs=pairs
local ipairs=ipairs
local string=string
local math=math
local os=os

local setfenv=setfenv
local unpack=unpack
local require=require


module(...)


function create(t)

	
local d={}
setfenv(1,d)

	for i,v in pairs(t) do -- start with a simple 1 deep copy
		d[i]=v
	end

--clear some bits?
	
-- an array of can flags so tests such as "if can.walk do this" reads as engrish	
-- an array of trigger functions to call that we can change in place

	for _,n in ipairs{"can","call"} do -- copy these slightly deeper
		local newtab={}
		for i,v in pairs( t[n] or {} ) do
			newtab[i]=v
		end		
		d[n]=newtab
	end

	hpmax=hp -- remember initial hp

	set={}
	get={}

	function set.name(v)       name=v end
	function get.name() return name   end
	
	function set.visible(v)       visible=v end
	function get.visible() return visible   end
	
	
--	function get.visible() return true end -- debug

	return d
	
end

