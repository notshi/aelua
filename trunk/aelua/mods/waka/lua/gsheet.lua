
local sys=require("wetgenes.aelua.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("html")

local fetch=require("wetgenes.aelua.fetch")

local cache=require("wetgenes.aelua.cache")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

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
	local t,err=get(srv,opts)
	local o={}
	
	if t and t.table and t.table.rows  and t.table.cols then
		for i,v in ipairs(t.table.rows) do
			local tab={}
			for i,v in ipairs(v and v.c or {} ) do
				local id=(t.table.cols[i].id) or i
				local s=(v and v.v) or ""
				
				-- stuff coming in seems to be a bit crazy, this forces it to 7bit ascii
				if type(s)=="string" then s=s:gsub("[^!-~%s]","") end

				tab[id]=s
			end
			if opts.hook then -- update this stuff?
				opts.hook(tab)
			end
			for id,s in pairs(tab) do
				o[#o+1]="{"..id.."=}"
				o[#o+1]=s
				o[#o+1]="{="..id.."}"
			end
			o[#o+1]="{"..(opts.plate or "item").."}"
		end
		s=table.concat(o)
	else
		s=err or "GSHEET IMPORT fail please reload page to try again."
	end

	return s
end

--
-- get a table given the opts
--
function get(srv,opts)

--"http://spreadsheets.google.com/tq?tq=select+*+limit+10+offset+0+&key=tYrIfWhE3Q1i8t8VLKgEZSA"

	local tq=(opts.query or "select *").." limit "..opts.limit.." offset "..opts.offset
	local url

	url="http://spreadsheets.google.com/tq?key="..opts.key
	url=url.."&v"..opts.v
	url=url.."&tq="..url_esc(tq)

	local cachename="waka_gsheet&"..url_esc(url)
	local datastr
	local err
	
	local data=cache.get(srv,cachename) -- check cache
	if data then return data end
	
	if not datastr then -- we didnt got it from the cache?
		datastr,err=fetch.get(url) -- get from internets
		if err then
			log(err)
		end
		if datastr then datastr=datastr.body end -- check
		if type(datastr)=="string" then -- trim some junk get string within the outermost {}
			datastr=datastr:match("^[^{]*(.-)[^}]*$")
		end
	end
	
	
--	local origsize=0
	
	if datastr then
	
--		origsize=datastr:len() or 0
		local suc
		suc,data=pcall(function() return json.decode(datastr) end) -- convert from json, hopefully
		if not suc then data=nil end
		
		if data then cache.put(srv,cachename,data,60*60) end
	end
		
	return data,err
end
