
-- pre fabricated rooms, dungeon building for the use of

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

local yarn_strings=require("yarn.strings")




keys={}

-- basic key, every map string uses this by default and then adds more or overides
keys.base={
	["# "]="wall",
	[". "]="space",
	["- "]="item_spawn",
	["= "]="bigitem_spawn",
	["@ "]="player_spawn",
	["< "]="stairs_up",
	["> "]="stairs_down",
}

strings={}

strings.bigroom=[[
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
]]

strings.home_bedroom=[[
# # # # # # # #
# . . . . = = #
# . . @ . = = #
# . . . . = = #
# . . . . = = #
# # # # # # # #
]]

strings.home_mainroom=[[
# # # # # # # # # #
# . . . . . . . . #
# . = = . . = = . #
# . = = . . = = . #
# . = = . . = = . #
# . = = . . = = . #
# . . . . . . . . #
# # # # # # # # # #
]]        

strings.home_entrance=[[
# # # # # # # #
# # = = = = # #
# = . . > . = #
# = . . . . = #
# # = = = = # #
# # # # # # # #
]]

function string_to_room(s,key)

	local r={}

	local lines=yarn_strings.split_lines(s)
	for i,v in ipairs(lines) do lines[i]=yarn_strings.trim(v).." " end -- trim, but add space back on end
	
	local xh=0
	for i,v in ipairs(lines) do if #v>xh then xh=#v end end -- find maximum line length

	local ls={}
	for i,v in ipairs(lines) do if #v==xh then ls[#ls+1]=v end end -- only keep lines of this length
	local yh=#ls
	xh=math.floor(xh/2) -- 2 chars to one cell
	
	xh=xh-2
	yh=yh-2
	
	if xh<0 then xh=0 end
	if yh<0 then yh=0 end
	
	r.xh=xh
	r.yh=yh
	
	r.name="unnnamed"
	
	r.cells={}
	for n=2,#ls-1 do -- skip top/bottom line
		local l=ls[n]
		local t={}
		r.cells[ #r.cells+1 ]=t
		for i=1+2,#l-2,2 do -- skip left/right chars
			local ab=l:sub(i,i+1)
			t[#t+1]=key[ab] or "space"
		end
	end
	
	return r
end


function get_room(name)

	local r

	if strings[name] then	
		r=string_to_room( strings[name] , keys.base )
	end

	return r
end



function map_opts(name)

	local opts={}
	opts.rooms={} -- required rooms for this map
	
	local function add_room(r) opts.rooms[#opts.rooms+1]=r	end
	
	if name=="home" then
		add_room(get_room("home_entrance"))
		add_room(get_room("home_bedroom"))
		add_room(get_room("home_mainroom"))
	end
	
	return opts

end

