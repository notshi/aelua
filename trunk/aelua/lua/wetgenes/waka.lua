
--
-- a waka is made of chunks
-- chunks are made of text that contains links
-- a word that begins with / or http: is a link
-- there is no waka markup, if you want markup then use xhtml
--

local table=table
local string=string


local string=string
local type=type
local tostring=tostring


module("wetgenes.waka")


-----------------------------------------------------------------------------
--
-- split on \n, each line also includes its own \n
--
-----------------------------------------------------------------------------
local function split_lines(text)
	local separator = "\n"
	
	local parts = {}  
	local start = 1
	
	local split_start, split_end = text:find(separator, start,true)
	
	while split_start do
		table.insert(parts, text:sub(start, split_end))
		start = split_end + 1
		split_start, split_end = text:find(separator, start,true)
	end
	
	if text:sub(start)~="" then
		table.insert(parts, text:sub(start) )
	end
	
	return parts
end



-----------------------------------------------------------------------------
--
-- split on whitespace, throw away all whitespace return only the words
--
-----------------------------------------------------------------------------
local function split_words(text,split)
	local separator = split or "%s+"
	
	local parts = {}  
	local start = 1
	
	local split_start, split_end = text:find(separator, start)
	
	while split_start do
		if split_start>1 then table.insert(parts, text:sub(start, split_start-1)) end
		start = split_end + 1
		split_start, split_end = text:find(separator, start)
	end
	
	if text:sub(start)~="" then
		table.insert(parts, text:sub(start) )
	end
	
	return parts
end

-----------------------------------------------------------------------------
--
-- split on whitespace, include this white space in its own token
--
-- such that a concat on the result would be a perfect reproduction of the original
--
-----------------------------------------------------------------------------
local function split_whitespace(text)
	local separator = "%s+"
	
	local parts = {}  
	local start = 1
	
	local split_start, split_end = text:find(separator, start)
	
	while split_start do
		if split_start>1 then table.insert(parts, text:sub(start, split_start-1)) end		-- the word
		table.insert(parts, text:sub(split_start, split_end))	-- the white space
		start = split_end + 1
		split_start, split_end = text:find(separator, start)
	end
	
	if text:sub(start)~="" then
		table.insert(parts, text:sub(start) )
	end
	
	return parts
end

-----------------------------------------------------------------------------
--
-- split a string in two on =
--
-----------------------------------------------------------------------------
local function split_equal(text)
	local separator = "="
	
	local parts = {}
	local start = 1
	
	local split_start, split_end = text:find(separator, start)
	
	if split_start and split_start>1 and split_end<#text then -- data either side of seperator
	
		return text:sub(1,split_start-1) , text:sub(split_end+1)
		
	end
	
	return nil
end

-----------------------------------------------------------------------------
--
-- take a multichunk of text and break it into named chunks
-- returns a lookup table of chunks and numerical list of chunks in the order they where first defined
-- body is always defined
--
-- a chunk is a line that begins with #
-- the part after the . and ending with whitespace is the chunk name
-- all text following this line is part of that chunk
-- the default section if none is give is "body", so any whitespace at the start of the file
-- before the first # line will be assigned into this chunk
-- data may follow this chunk name, if multiple chunks of the same name
-- are defined they are simple merged into one
-- and each #chunk line is combined into one chunk
--
-- use option=value after the section name to provide options, so somthing like this
--
-- #name opt=val opt=val opt=val
-- # opt=val
-- here is some text
-- # opt=val
-- here is some more text
--
-- is a valid chunk, all of the opt=val will be assigned to the same chunk
-- and all the other text will be joined as that chunks body
--
-----------------------------------------------------------------------------
function text_to_chunks(text)

	local chunks={}
	
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
				if a then chunk.opts[a]=b end
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

			chunk=manifest_chunk(v,chunk)
		
		else -- normal lime add to the current chunk
		
			if not chunk then chunk=manifest_chunk("#body") end --sanity
			
			table.insert(chunk.lines , v)
		end
	
	end
	
	return chunks
	
end


-----------------------------------------------------------------------------
--
-- get a html string given a chunk
--
-- \n are turned into <br/> tags
-- and words that look like links are turned into links
-- any included html should get escaped so this is "safe" to use on user input
--
-- we need to lnow the baseurl of this page when building links, if this is not given
-- then relative links are not built
--
-----------------------------------------------------------------------------
function chunk_to_html(chunk,baseurl)

	local r={}
	
	local function esc(s)
		local escaped = { ['<']='&lt;', ['>']='&gt;', ["&"]='&amp;' , ["\n"]='<br/>' }
		return (s:gsub("[<>&\n]", function(c) return escaped[c] end))
	end
	local function link( url , str )
		table.insert(r,"<a href=\""..url.."\">"..esc(str).."</a>")
	end
	local function text( str )
		table.insert(r,esc(str))
	end

	for i=1,#chunk.lines do local line=chunk.lines[i]
	
		local tokens=split_whitespace(line)
		
		for i2=1,#tokens do local token=tokens[i2]
		
			local done=false
			
			local len=token:len()
			
			if len>=2 then -- too short to be a link
			
				local c1=token:sub(1,1) -- some chars to check
				
				if c1 == "/" then -- a very simple link relative to where we are
				
					local chars="[%w/%-_#]+"
					
					if token:sub(1,3)=="///" then chars="[%w/%-_#%.:]+" end -- allow common domains chars
				
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
				end
				
			end
			
			
			if not done then -- unhandled token, just add it
				text(token)				
			end
			
		
		
		end
	
	end
	
	
	return table.concat(r)

end

