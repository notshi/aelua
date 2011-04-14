

local log=require("wetgenes.aelua.log").log -- grab the func from the package


local math=math
local string=string
local table=table
local os=os

local ipairs=ipairs
local pairs=pairs
local tostring=tostring
local tonumber=tonumber
local type=type
local pcall=pcall
local loadstring=loadstring

local require=require

module("admin.ipv4")

local tab=require("admin.ipv4_tab").data
local tab_max=(#tab/2)-1

-- turn an ip into a 32 bit number, or 0 if not a valid ipv4
function ipnum(ip)

local num=0

	if type(ip)=="number" then
	
		num=ip
		
	elseif type(ip)=="string" then
	
		if not ip:find("[^%.%d]") then -- ignore anything else
			for word in ip:gmatch("[^%.]+") do num=num*256+tonumber(word) end
		end
	end
	
	if num<0 then num=0 end
	if num>4294967295 then num=4294967295 end
	return num

end


-- lookup a country code from an ipv4 which should be turned into an integer

function country(ip)

	ip=ipnum(ip) -- force into a number
	
	local function get(i)
		i=math.floor(i)
		if i<0 then i=0 end
		if i>tab_max then i=tab_max end
		
		local v={}
		v.idx=i
		v.start=tab[1+(i*2)]
		v.code=tab[2+(i*2)]
		v.next=tab[3+(i*2)]
		if not v.next then v.next=4294967295 end
		return v
	end
	
	local function check(v)
		if ip>=v.start and ip<v.next then return true end
	end

	local n=get(0)	-- start of range
	local x=get(tab_max) -- end of range
	
	if check(n) then return n.code end -- catch 0 values at this point
	if check(x) then return x.code end

	while true do -- simple binary search
		local t=get( (x.idx+n.idx)/2 )
		if check(t) then return t.code end -- found it
		if t.start>ip then x=t end -- new max
		if t.next<=ip then n=t end -- new min
		if (x.idx-n.idx)<1 then break end -- not found, ranges data must be bad
	end

	return "ZZ" -- default of unknown
end
