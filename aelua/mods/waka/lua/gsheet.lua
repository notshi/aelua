
local sys=require("wetgenes.aelua.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("html")

local fetch=require("wetgenes.aelua.fetch")

local cache=require("wetgenes.aelua.cache")

local json=require("json")

local setmetatable=setmetatable
local type=type
local tostring=tostring
local ipairs=ipairs
local pairs=pairs
local pcall=pcall

local table=table

module("waka.gsheet")

-- we need to be able to pull in data from a google sheet this means a bit of url get and a bit of cache
-- this data is then turned into a waka macro string for rendering

function getwaka(srv,opts)

	local s=""
	local t=get(srv,opts)
	local o={}
	
	if t and t.table and t.table.rows then
		for i,v in ipairs(t.table.rows) do
			for i,v in ipairs(v and v.c or {} ) do
				o[#o+1]="{V"..i.."=}"
				o[#o+1]=v and v.v
				o[#o+1]="{=V"..i.."}"
			end
			o[#o+1]="{"..(opts.plate or "item").."}"
		end
		s=table.concat(o)
	end

	return s
end

--
-- get a table given the opts
--
function get(srv,opts)

--"http://spreadsheets.google.com/tq?tq=select+*+limit+10+offset+0+&key=tYrIfWhE3Q1i8t8VLKgEZSA"

	local tq="select * limit "..opts.limit.." offset "..opts.offset
	local url

	url="http://spreadsheets.google.com/tq?key="..opts.key
	url=url.."&v"..opts.v
	url=url.."&tq="..url_esc(tq)

	local cachename="waka_gsheet&"..url_esc(url)
	local data=cache.get(cachename)
	
	if data then return data end -- we got it from the cache
	
	data=fetch.get(url) -- get from internets
	if data then data=data.body end -- check
	
	if type(data)=="string" then -- trim some junk get string within the outermost {}
		data=data:match("^[^{]*(.-)[^}]*$")
	end
	
	local suc
	suc,data=pcall(function() return json.decode(data) end) -- convert from json, hopefully
	if not suc then data=nil end
	
	cache.put(cachename,data,60*60)
	return data
end
