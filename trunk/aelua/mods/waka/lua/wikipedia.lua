
local sys=require("wetgenes.aelua.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("html")

local fetch=require("wetgenes.aelua.fetch")

local cache=require("wetgenes.aelua.cache")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local json=require("json")

local simpxml=require("wetgenes.simpxml")

local setmetatable=setmetatable
local type=type
local tostring=tostring
local ipairs=ipairs
local pairs=pairs
local pcall=pcall

local table=table
local string=string

module("waka.wikipedia")

-- pull in data from a wikipedia page
-- we try and parse and build waka chunks from this raw content

function getwaka(srv,opts)

	local s=""
	local t,err
	
	if opts.search then -- want to search
	
		t,err=search(srv,opts)
		s=err

		if t and t.query and t.query.search then
			local tt=t.query.search
			for i,v in ipairs(tt) do
				v.name=string.gsub(v.title," ","_")
			end
			tt.plate=opts.plate or"<h1>{it.title}</h1>{it.snippet}"
			return tt
		end

	else
	
	
		t,err=get(srv,opts)
		s=err
		if t then
			local html=simpxml.descendent(t,"html")
			local head=simpxml.child(html,"head")
			local body=simpxml.child(html,"body")
			
-- remove all scripts		
			for i,v in ipairs( simpxml.descendents(body,"script") ) do
				for ii,vv in pairs(v) do v[ii]=nil end
			end
			
-- remove all metadata
			for i,v in ipairs( simpxml.descendents(body,"table") ) do
				local class=simpxml.attr(v,"class")
				local id=simpxml.attr(v,"id")
				if ( class and ( class:match("metadata") or class:match("autocollapse") )) or id=="toc" then
					for ii,vv in pairs(v) do v[ii]=nil end
				end
			end
			for i,v in ipairs( simpxml.descendents(body,"div") ) do
				local class=simpxml.attr(v,"class")
				if ( class and ( class:match("catlinks") )) then
					for ii,vv in pairs(v) do v[ii]=nil end
				end
			end
			for i,v in ipairs( simpxml.descendents(body,"span") ) do
				local class=simpxml.attr(v,"class")
				if ( class and ( class:match("edit") )) then
					for ii,vv in pairs(v) do v[ii]=nil end
				end
			end
			
-- fix links
			for i,v in ipairs( simpxml.descendents(body,"a") ) do
				local href=simpxml.attr(v,"href")
				if href then
					if href:sub(1,1)=="#" then
						for ii,vv in pairs(v) do
							v[ii]=nil
						end
					elseif href:sub(1,1)=="/" then -- redirect
						simpxml.attr(v,"href","http://en.wikipedia.org"..href)
					end
				end
			end

-- find content
			local content
			for i,v in ipairs( simpxml.descendents(body,"div") ) do
				local id=simpxml.attr(v,"id")
				if id and id:match("bodyContent") then
					content=v
					for i=1,7 do v[i]="" end
					break
				end
			end

			local infobox
			for i,v in ipairs( simpxml.descendents(body,"table") ) do
				local class=simpxml.attr(v,"class")
				if class and class:match("infobox") then
					infobox=v
					break
				end
			end

			local info={}
			if infobox then
				for i,v in ipairs( simpxml.descendents(infobox,"tr") ) do
					local td=simpxml.descendents(v,"td")
					if td[2] then
						local a1=simpxml.descendents(td[1],"a")
						local a2=simpxml.descendents(td[2],"a")
						local val={}
						local st="http://en.wikipedia.org/wiki/"
						for i,v in ipairs(a2) do
							local s=simpxml.attr(v,"href")
							if s:sub(1,#st)==st then
								val[#val+1]=s:sub(#st+1)
							end
						end
						for i,v in ipairs(a1) do
							local s=simpxml.attr(v,"href")
							if s:sub(1,#st)==st then
								s=s:sub(#st+1)
								info[s]=val
							end
						end
					end
				end

-- find image		
				local img=simpxml.descendent(infobox,"img")
				if img then img=simpxml.attr(img,"src") end
				if img then info.img=img end

-- find name
				local name=simpxml.descendent(infobox,"tr")
				if name then name=simpxml.descendent(name,"i") end
				if name then info.name=name[1] end
				
			end
			
			if not info.name then info.name=opts.name:gsub("_"," ") end

-- debug
--[[
			for i,v in pairs(info) do
				log(tostring(i).."="..tostring(v))
			end
]]
			
	-- turn content back into html string		
			if content then
				info.body=simpxml.unparse(content)
				info.plate=opts.plate or"{it.body}"
				return info
			end	
		end
	end
	
	return s
end

--
-- get a table given the opts
--
function get(srv,opts)
--Fallout:_New_Vegas
	local url=opts.url or "http://en.wikipedia.org/wiki/"..(opts.name or "Fallout:_New_Vegas")	
	local cachename="waka_wikipedia&"..url_esc(url)
	local datastr
	local err
	
	local data=cache.get(srv,cachename) -- check cache
	if data then return data end
	
	if not datastr then -- we didnt got it from the cache?
		datastr,err=fetch.get(url) -- get from internets
		if err then
			log(err)
		end
		if datastr then datastr=datastr.body end -- we only care about the body
	end
	
	
	if datastr then
		local suc
		suc,data=pcall(function() return simpxml.parse(datastr) end) -- convert from xhtml, hopefully
		if not suc then data=nil err="malformed xml" end
		if data then cache.put(srv,cachename,data,60*60) end
	end
		
	return data,err
end


--
-- find some pages given the opts
--
function search(srv,opts)
--Fallout:_New_Vegas
	local url=opts.url or "http://en.wikipedia.org/w/api.php?action=query&list=search&format=json"
	
	if opts.search then
		url=url.."&srsearch="..opts.search
		--"chulip+(incategory:Xbox_360_Live_Arcade_games+OR+incategory:PlayStation_2_games)"
	end
	if opts.limit then
		url=url.."&srlimit="..opts.limit
	end
	if opts.offset then
		url=url.."&sroffset="..opts.offset
	end
	
	local cachename="waka_wikipedia&"..url_esc(url)
	local datastr
	local err
	
	local data=cache.get(srv,cachename) -- check cache
	if data then return data end
	
	if not datastr then -- we didnt got it from the cache?
		datastr,err=fetch.get(url) -- get from internets
		if err then
			log(err)
		end
		if datastr then datastr=datastr.body end -- we only care about the body
	end
	
	
	if datastr then
		local suc
		suc,data=pcall(function() return json.decode(datastr) end) -- convert from json, hopefully
		if not suc then data=nil err="malformed json" end
		if data then cache.put(srv,cachename,data,60*60) end
	end
		
	return data,err
end

