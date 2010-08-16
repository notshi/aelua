
--
-- a waka is made of chunks
-- chunks are made of text that contains links
-- a word that begins with / or http: is a link
-- there is no waka markup, if you want markup then use xhtml
--

local table=table
local string=string


local ipairs=ipairs
local pairs=pairs

local string=string
local type=type
local tostring=tostring

-- my string functions
local str=require("wetgenes.string")


module("wetgenes.waka")

local split_lines		=str.split_lines
local split_words		=str.split_words
local split_whitespace	=str.split_whitespace
local split_equal		=str.split_equal

-----------------------------------------------------------------------------
--
-- take some text and break it into named chunks
-- returns a lookup table of chunks and numerical list of these chunks in the order they where first defined
-- body is the default chunk name
--
-- a chunk is a line that begins with #
-- the part after the # and ending with whitespace is the chunk name
-- all text following this line is part of that chunk
-- the default section if none is give is "body", so any whitespace at the start of the file
-- before the first # line will be assigned to this chunk
-- data may follow this chunk name, if multiple chunks of the same name
-- are defined they are simple merged into one
-- and each #chunk line is combined into one chunk data
--
-- use option=value after the section name to provide options, so somthing like this
--
-- #name opt=val opt=val opt=val
-- # opt=val
-- here is some text
-- # opt=val
-- here is some more text
-- ## special comment, this line is ignored
-- ## comments are just a line that begins with two hashes
--
-- is a valid chunk, all of the opt=val will be assigned to the same chunk
-- and all the other text will be joined as that chunks body
--
-- pass in chunks and you can merge multiple texts into one chunk
--
-----------------------------------------------------------------------------
function text_to_chunks(text,chunks)

	chunks=chunks or {}

	local function manifest_chunk(line,oldchunk)
		local opts=split_words( line:sub(2) ) -- skip # at start of line
		local name=string.lower( opts[1] or "body" )
		local chunk
		local c2=line:sub(2,2)
		
		if c2:find("%s") then -- if first char after # is whitespace, then use the old chunk 
			chunk=oldchunk
		end
		
		if not chunk then
			chunk=chunks[name] -- do we already have this chunk?
		end
		
		if chunk then -- update an old chunk
		
			for i=1,#opts do local v=opts[i]
				table.insert( chunk.opts , v ) -- add extra opts
				local a,b=split_equal(v)
				if a then chunk.opts[a]=b end
			end
			
		else -- create a new chunk
		
			chunk={} -- make default chunk
			
			for i=1,#opts do local v=opts[i]
				local a,b=split_equal(v)
				if a then opts[a]=b end
			end
			
			chunk.id=#chunks+1
			chunk.name=name
			chunk.opts=opts
			chunk.lines={}
			
			chunks[chunk.id]=chunk		-- save chunk in chunks as numbered id
			chunks[chunk.name]=chunk	-- and as name
		end
		
		return chunk
	end
		
	local lines=split_lines(text)
	
	local chunk
	
	for i=1,#lines do local v=lines[i] -- ipairs
		
		local c=v:sub(1,1) -- the first char is special
		
		if c=="#" then -- start of chunk

			if v:sub(2,2)~="#" then -- skip all comments

				chunk=manifest_chunk(v,chunk)

			end
	
		else -- normal lime add to the current chunk
		
			if not chunk then chunk=manifest_chunk("#body") end --sanity
			
			table.insert(chunk.lines , v)
		end
	
	end
	
	for i=1,#chunks do local v=chunks[i] -- perform some final actions on all chunks
	
		v.text=table.concat(v.lines) -- merge the split lines back together into one string
		
	end
	
	return chunks
	
end

-----------------------------------------------------------------------------
--
-- merge source data into dest data, dest data may be nil in which case this 
-- works like a copy. Return the dest chunk. It is intended that you have a
-- a number of chunks and then merge them together into a final data chunk
-- using this function, the first merge creates a new dest chunk. the final result
-- will have a new ordering depending on the merged chunks but the numerical array
-- can still be used to loop through chunks
--
-----------------------------------------------------------------------------
function chunks_merge(dest,source)

	local dest=dest or {}
	
	for i,v in ipairs(source) do
	
		local c=dest[v.name] -- merge or
		if not c then -- make a new chunk
			c={}
			c.id=#dest+1
			c.name=v.name
			c.opts={}
			dest[c.id]=c -- link it into dest by array
			dest[c.name]=c -- and by name
		end

		c.lines=v.lines -- overwritten
		c.text=v.text -- overwritten
		
		for i,v in pairs(v.opts) do -- merge options
			c.opts[i]=v
		end

	end

	return dest
end


-----------------------------------------------------------------------------
--
-- get a html given some simple waka text
--
-- \n are turned into <br/> tags
-- and words that look like links are turned into links
-- any included html should get escaped so this is "safe" to use on user input
--
-- aditional opts
--
-- we need to know the base_url of this page when building links, if this is not given
-- then relative links may bork?
--
-- setting escape_html to true prevents any html from getting through
--
-----------------------------------------------------------------------------
function waka_to_html(input,opts)
	opts=opts or {}

local base_url=opts.base_url or ""
local escape_html=opts.escape_html or false

	local r={}
	local esc
	if escape_html then -- simple html escape
		esc=function(s) 
			local escaped = { ['<']='&lt;', ['>']='&gt;', ["&"]='&amp;' , ["\n"]='<br/>\n' }
			return (s:gsub("[<>&\n]", function(c) return escaped[c] or c end))
		end
	else -- no escape just convert \n to <br/>
		esc=function(s) 
			local escaped = { ["\n"]='<br/>\n' }
			return (s:gsub("[\n]", function(c) return escaped[c] or c end))
		end
	end
	
	local function link( url , str )
		table.insert(r,"<a href=\""..url.."\">"..esc(str).."</a>")
	end
	local function text( str )
		table.insert(r,esc(str))
	end

	local tokens=split_whitespace(input)
	
	for i2=1,#tokens do local token=tokens[i2]
	
		local done=false
		
		local len=token:len()
		
		if len>=2 then -- too short to be a link
		
			local c1=token:sub(1,1) -- some chars to check
			
			if c1 == "/" then -- a very simple link relative to where we are
			
				local chars="[%w/%-%+_#]+"
				
				if token:sub(1,3)=="///" then chars="[%w/%-%+_#%.:]+" end -- allow common domain chars
			
				local s=token:sub(2) -- skip this first char
				
				local f1,f2=s:find(chars)
				if f1 then -- must find a word
					local s1=s:sub(f1,f2)
					local ss=split_words(s1,"/")
					local tail=ss[#ss] 
					link(s1,tail)
					if f2<s:len() then -- some left over string
						text(s:sub(f2+1))
					end
					done=true
				end
				
			elseif token:sub(1,7)=="http://" then
					link(token,token)
					done=true

			elseif token:sub(1,8)=="https://" then
					link(token,token)
					done=true
			end
			
		end
		
		
		if not done then -- unhandled token, just add it
			text(token)				
		end
	
	end
	
	return table.concat(r)
end

