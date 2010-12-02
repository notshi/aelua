
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


local strings=require("yarn.strings")

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

	-- build a requester
	function build_request(t)
	
-- t[1] the main body of text, t[2++] are your options and are displayed on lines below this text
-- every single line is wrapped and an id is set for each line so you can work out what has
-- been selected
		
		local lines={}
		for id=1,#t do
			if id==2 then -- divider
				lines[#lines+1]={s="",id=id}
			end
			local ls=strings.smart_wrap(t[id],32)
			for i=1,#ls do lines[#lines+1]={s=ls[i],id=id} end
		end
		
		return lines
	end

	return d
	
end
