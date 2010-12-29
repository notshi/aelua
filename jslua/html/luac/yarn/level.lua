
-- a collection of everything


local _G=_G

local debug=debug
local table=table
local ipairs=ipairs
local pairs=pairs
local string=string
local math=math
local os=os

local setfenv=setfenv
local unpack=unpack
local require=require
local type=type


module(...)
local yarn_map=require("yarn.map")
local yarn_room=require("yarn.room")
local yarn_cell=require("yarn.cell")
local yarn_item=require("yarn.item")
local yarn_attr=require("yarn.attr")

local yarn_prefab=require("yarn.prefab")
local yarn_attrdata=require("yarn.attrdata")


function create(t,_up)

local d={}
setfenv(1,d)

	up=_up

	time_passed=0
	time_update=0
	
	xh=t.xh or 30
	yh=t.yh or 30

	rooms={}
	cells={}
	items={}
	chars={}
	attrs={}
	
	cellfind={}
	celllist={}

-- create blank cells

	for y=0,yh-1 do
		for x=0,xh-1 do
			local i=x+y*xh
			cells[i]=yarn_cell.create({ level=d, xp=x, yp=y, id=i })
		end
	end

--	function draw_map(m) map.draw_map(m) end
	function get_asc(x,y)
		local cell=get_cell(x,y)
		return (cell and cell.asc())
	end
	
	function get_cell(x,y)
		if x<0 then return nil end
		if x>=xh then return nil end
		if y<0 then return nil end
		if y>=yh then return nil end
		return cells[ x+y*xh ]
	end

-- iterate an area of cells	
	function cpairs(x,y,w,h)
		return function(a,i)
			local px=i%w
			local py=(i-px)/w
			if py>=h then return end
			return i+1,get_cell(x+px,y+py)
		end, cells, 0
	end
	
	function new_item(n,l)
		local at
		if type(n)=="string" then
			at=yarn_attrdata.get(n,l)
		else
			at=n
			n=at.name
		end
		local it=yarn_item.create( at ,d)
		items[it]=true -- everything lives in items list
		return it
	end
	function del_item(it)
		items[it]=nil
		chars[it]=nil
		it.del()
	end
	
	function rand(a,b)
		if a>=b then return a end
		return math.random(a,b)
	end

-- get a random room	
	function rand_room(t)
		local n=0
		for i,v in ipairs(rooms) do if v.xh>1 and v.yh>1 then n=n+1 end end -- count rooms
		n=rand(1,n)
		for i,v in ipairs(rooms) do
			if v.xh>1 and v.yh>1 then
				n=n-1
				if n<1 then return v end -- found it
			end
		end
	end
	
-- get a random cell in the given range
	function rand_cell(t)
		local x=rand(t.xp,t.xp+t.xh-1)
		local y=rand(t.yp,t.yp+t.yh-1)
		return get_cell(x,y)
	end

-- get a random cell in a random room

	function rand_room_cell(t)
		return rand_cell(rand_room(t))
	end
	
	do
		local opts=yarn_prefab.map_opts("home")
		opts.xh=d.xh
		opts.yh=d.yh
		map=yarn_map.create(opts) -- create an empty map, this is only a room layout
	end
	
-- now turn that generated map into real rooms we can put stuff in
	for i,v in ipairs(map.rooms) do
		rooms[i]=yarn_room.create({ level=d, xp=v.x, yp=v.y, xh=v.xh, yh=v.yh, })
		rooms[i].opts=v.opts
	end

-- find link door locations	
	for i,v in ipairs(rooms) do v.find_doors() end
	

	
	for i,v in ipairs(rooms) do
		v.post_create()
	end
	
	for i,r in ipairs(rooms) do
		if r.opts then -- special?
			local cs=r.opts.cells
			for y=1,#cs do
				local v=cs[y]
				for x=1,#v do
					local n=v[x]
					
					if n=="space" then -- do nothing
					else
						local c=get_cell(r.xp+x-1,r.yp+y-1)
						if r.opts.callback then
							r.opts.callback({call="cell",cell=c,name=n,level=d,room=r})
						end
					end
				end
			end
			if r.opts.callback then
				r.opts.callback({call="room",level=d,room=r})
			end
		end
	end
	
	player=new_item( "player" )
	player.set_cell( cellfind["player_spawn"] or rand_room_cell({}) )
	
	for i=1,10 do
		c=rand_room_cell({})
		if not c.char then
			local p=new_item( "ant" )
			p.set_cell( c )
		end
	end

	for i=1,5 do
		c=rand_room_cell({})
		if not c.char then
			local p=new_item( "blob" )
			p.set_cell( c )
		end
	end
	
	key_repeat=nil
	key_repeat_count=0
	
	function key_clear()
		key_repeat=nil
	end
	
	function key_check()
		key_repeat_count=key_repeat_count+1
		if key_repeat_count>=10 then
			key_do(key_repeat)
		end
	end
	
	function key_do(key)
	
		if key=="space" or key=="enter" then
		
			up.menu.show_player_menu(player)
			
		end
		
		key_repeat_count=0 -- always zero the repeat counter
	
		local vx=0
		local vy=0
		
		if key=="up" then
			vx=0
			vy=-1
		elseif key=="down" then
			vx=0
			vy=1
		elseif key=="left" then
			vx=-1
			vy=0
		elseif key=="right" then
			vx=1
			vy=0
		end
		
		if vx~=0 or vy~=0 then
			time_update=time_update+player.move(vx,vy)
			return true
		end
	end
	
	function keypress(ascii,key,act)
	
		if act=="down" then
		
			key_repeat=key
			key_repeat_count=0
			
			key_do(key_repeat)
			
		elseif act=="up" then -- an up key cancels all repeats
		
			if key_repeat==key then
				key_repeat=nil
			end
		end
		
	end
	
	function update()
		key_check()
		
		if time_update==0 then return 0 end
--print(time_passed)

-- regen health?
--		player.attr.hp=math.floor(player.attr.hp+time_update)
--		if player.attr.hp > player.attr.hpmax then player.attr.hp = player.attr.hpmax end
		
		for v,b in pairs(items) do
			v.update()
		end
		
		if display_msg_time<time_passed then -- report your most important stats in msg form
		
			local item=player.cell.get_item()
			
			if item then -- standing on an item
				set_msg(item.view_text())
			elseif player.attr.hp~=player.attr.hpmax then
				set_msg("Your health is ".. player.attr.hp .."/".. player.attr.hpmax )
			else
				set_msg("You have scored "..player.attr.score .." points.")
			end
		end

		local t=time_update
		time_passed=time_passed+time_update
		time_update=0
		return t
	end
	
	display_msg=nil
	display_msg_time=0
	function set_msg(a)
		display_msg=a
		display_msg_time=time_passed
	end
	function add_msg(a)
		if display_msg_time<time_passed then display_msg=nil end -- do not add to previously displayed msgs
		if display_msg then display_msg=display_msg.." " else display_msg="" end
		display_msg=display_msg..a
		display_msg_time=time_passed
	end
	function get_msg()
		return display_msg or ""
	end

	return d
	
end

