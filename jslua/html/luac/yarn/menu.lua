
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
local pairs=pairs


module(...)
local strings=require("yarn.strings")
local yarn_level=require("yarn.level")
local attrdata=require("yarn.attrdata")


function create(t,up)

local d={}
local us=d
setfenv(1,d)

	stack={}

	dirty=0
	cursor=0
	
	-- set a menu to display
	function show(top)
	
		if #stack>0 then
			stack[#stack].cursor=cursor -- remember cursor position
		end

		stack[#stack+1]=top --push
		
		if top.call then top.call(top) end -- refresh
		
		display=top.display
		cursor=top.cursor or 1
		
		dirty=1
	end
	
	-- go back to the previous menu
	function back()

		stack[#stack]=nil -- this was us
		
		if #stack==0 then return hide() end -- clear all menus
		
		local top=stack[#stack] -- pop up a menu
		
		if top.call then top.call(top) end -- refresh
		
		display=top.display
		cursor=top.cursor or 1
		
		dirty=1
	end
	
	-- stop showing all menus and clear the stack

	function hide()
		stack={}
		display=nil
		dirty=1
	end


	function keypress(ascii,key,act)
		if not display then return end
		
		dirty=1
		
		local tab=display[ cursor ]
		
		if tab.tab then tab=tab.tab end -- use this data
		
		if act=="down" then
		
			if key=="space" or key=="enter" then
			
				if tab.call then -- do this
				
					tab.call( tab )
					
				else -- just back by default
				
					back()
				
				end
			
			elseif key=="backspace" then
			
				hide()
			
			elseif key=="up" then
			
				cursor=cursor-1
				if cursor<1 then cursor=#display end
			
			elseif key=="down" then
				
				cursor=cursor+1
				if cursor>#display then cursor=1 end
			
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
		
		local top=stack[#stack]

		up.asc_draw_box(1,1,38,#display+4)
		
		if top.title then
			local title=" "..(top.title:upper()).." "
			local wo2=math.floor(#title/2)
			up.asc_print(20-wo2,1,title)
		end
		
		for i,v in ipairs(display) do
			up.asc_print(4,i+2,v.s)
		end
		
		up.asc_print(3,cursor+2,">")
		
	end

	-- build a requester
	function build_request(t)
	
-- t[1++].txt is the main body of text, t[1++].use is a call back function if this is
-- selectable, if there is no callback then selecting that option just hides the menu

		local lines={}
		for id=1,#t do
			local ls=strings.smart_wrap(t[id].txt,32)
			for i=1,#ls do lines[#lines+1]={s=ls[i],id=id,tab=t[id]} end
		end
		
		return lines
	end


	function show_player_menu(player)
		local top={}
		
		top.title="look around you"

		top.call=function(tab)
		
			local tab={}
			
	-- add cancel option
			tab[#tab+1]={
				txt=[[..]],
				call=function(it)
					back()
				end
			}
			
	-- add backpack option
			tab[#tab+1]={
				txt=[[your loot and tools]],
				call=function(it)
					show_loot_menu(player)
				end
			}
			
			local items={}
			for i,v in player.cell.bordersplus() do
				for item,b in pairs(v.items) do
					items[#items+1]=item
				end				
			end
			
			for i,v in ipairs(items) do
				if v.call.acts then				
					tab[#tab+1]={
						txt=v.desc,
						call=function(it)
							show_item_menu(v)
						end
					}
				end
			end
			

			top.display=build_request(tab)
		end
		
		show(top)
	end


	function show_loot_menu(player)
		local top={}
		
		top.title="your loot and tools"
		
		top.call=function(tab)
		
			local tab={}
			
-- add cancel option
			tab[#tab+1]={
				txt=[[..]],
				call=function(it)
					back()
				end
			}
			
			top.display=build_request(tab)
		end
		
		show(top)
	end

	function show_item_menu(item)
		local top={}

		top.title=item.desc
		
		top.call=function(tab)
		
			local tab={}
			local player=item.level.player
	-- add cancel option
			tab[#tab+1]={
				txt=[[..]],
				call=function(it)
					back()
				end
			}
			

			
			local acts=item.call.acts(item,player)
			
			for i,v in ipairs(acts) do
				tab[#tab+1]={
					txt=v,
					call=function(it)
						if item.call[v] then
							item.call[v](item,player)
						end
					end
				}
			end

			top.display=build_request(tab)
		end
		
		show(top)
	end
	
	function show_stairs_menu(it,by)
		local top={}

		local goto_level=function(name,pow)
			local main=it.level.main
			main.level=main.level.destroy()
			main.level=yarn_level.create(attrdata.get(name,pow,{xh=40,yh=28}),main)
			main.menu.hide()
		end
		
		top.title=it.desc
		
		top.call=function(tab)
		
			local tab={}
			local player=it.level.player
	-- add cancel option
			tab[#tab+1]={
				txt=[[..]],
				call=function(it)
					back()
				end
			}

			tab[#tab+1]={
				txt="town (0)",
				call=function()
					goto_level("level.town",0)
				end
			}
			
			for i=it.stairs_min,it.stairs_max do
				tab[#tab+1]={
					txt=it.stairs.." ("..i..")",
					call=function()
						goto_level("level."..it.stairs,i)
					end
				}
			end
			
			top.display=build_request(tab)
		end
		
		show(top)
	end
	
	function show_text(title,display)
		local top={}

		local tab={}
-- add cancel option
		tab[#tab+1]={
			txt=[[..]],
			call=function(it)
				back()
			end
		}
			
		tab[#tab+1]={
			txt=display,
			call=function(it)
				hide()
			end
		}

		top.title=title
		top.display=build_request(tab)
		top.cursor=2
		
		show(top)		
	end
	
	return d
	
end
