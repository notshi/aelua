
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



module(...)


function create(t,up)

local d={}
setfenv(1,d)

	dirty=0
	
	-- set a menu to display
	function show(t,_curser)

		display=t
		curser=_curser or 1
		
		dirty=1
	end
	

	-- stop showing a menu

	function hide()
		display=nil
		dirty=1
	end


	function keypress(ascii,key,act)
		if not display then return end
		
		dirty=1
		
		if act=="down" then
		
			if key=="space" then
			
				hide()
			
			elseif key=="up" then
			
				curser=curser-1
				if curser<1 then curser=#display end
			
			elseif key=="down" then
				
				curser=curser+1
				if curser>#display then curser=1 end
			
			end
		
		end

		
		return true
	end


	-- display a menu
	function update()
	
		local t=dirty
		dirty=0
		
		return t
	end
	
	-- display a menu
	function draw()

		if not display then return end
		
		up.asc_draw_box(1,1,38,#display+4)
		
		for i,v in ipairs(display) do
			up.asc_print(4,i+2,v.s)
		end
		
		up.asc_print(3,curser+2,">")
		
	end


	return d
	
end
