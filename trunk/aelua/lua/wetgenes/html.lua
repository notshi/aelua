
local table=table
local string=string

local type=type
local tostring=tostring
local setmetatable=setmetatable

module("wetgenes.html")


-----------------------------------------------------------------------------
--
-- replace tags in {} in the string with data provided
-- allow sub table look up with a.b notation in the name
--
-----------------------------------------------------------------------------
function replace(a,d)

return (string.gsub( a , "{([%w%._%-]-)}" , function(a) -- find only words and "._-" tightly encased in {}
-- this means that almost all legal use of {} in javascript will not match at all.
-- Even when it does (probably as a "{}") then it is unlikley to accidently find anything in the d table
-- so the text will just be returned as is.
-- So it may not be safe, but it is simple to understand and perfecty fine under most use cases.

	local f
	
	f=function(a,d) -- look up a in table d
	
--		if string.len(a)>256 then return "{"..a.."}" end -- do not even try with really large strings?
	
		local t=d[a]
		if t then
			if type(t)=="table" then return table.concat(t) end -- if a table then join its contents
			return tostring(t) -- simple find, make sure we return a string
		end
		
		local a1,a2=string.find(a, "%.") -- try and split on first "."
		if not a1 then return "{"..a.."}" end -- didnt find a dot so return look up value keeping {}
		
		a1=string.sub(a,1,a1-1) -- the bit before the .
		a2=string.sub(a,a2+1) -- the bit after the .
		
		local dd=d[a1] -- use the bit befre the dot to find the sub table
		
		if type(dd)=="table" then -- check we got a table
			return f(a2,dd) -- tail call this function
		end
		
		return "{"..a.."}" -- couldnt find anything return input string
	end

	return f(a,d)
	
end ))

end



-----------------------------------------------------------------------------
--
-- build a string from a template,  with a table to be used as its environment
--
-- this environment will not get modified by the called function as it is wrapped here
--
-- even though the calling function is free to modify the table it gets
--
-----------------------------------------------------------------------------
get=function(html,src,env)

	local new_env={}

	if env then setmetatable(new_env,{__index=env})	end -- wrap to protect

	if html[src] then src=html[src] end
	
	if type(src)=="function" then return src(new_env) end
	
	if type(src)=="string" and env then return replace(src,new_env) end

	return tostring(src)
end


-----------------------------------------------------------------------------
--
-- very basic html esc to stop tags and entities from doing bad things
-- running text submitted from a user through this function should stop it from doing
-- anything other than just being text, it doesnt guarantee that it is valid xhtml / whatever
-- We just turn a few important characters into entities.
--
-----------------------------------------------------------------------------
function esc(s)
	local escaped = { ['<']='&lt;', ['>']='&gt;', ["&"]='&amp;' }
	return (s:gsub("[<>&]", function(c) return escaped[c] end))
end

-----------------------------------------------------------------------------
--
-- basic url escape, so as not to trigger url get params or anything else by mistake 
-- so = & # % ? " ' are bad and get replaced with %xx
--
-----------------------------------------------------------------------------
function url_esc(s)
	return string.gsub(s, "([&=%%%#%?%'%\" ])", function(c)
		return string.format("%%%02x", string.byte(c))
	end)
end

-----------------------------------------------------------------------------
--
-- a url escape, that only escapes the string deliminators ' and " 
--
-----------------------------------------------------------------------------
function url_esc_string(s)
	return string.gsub(s, "(['%\" ])", function(c)
		return string.format("%%%02x", string.byte(c))
	end)
end

-----------------------------------------------------------------------------
--
-- convert any %xx into single chars
--
-----------------------------------------------------------------------------
function url_unesc(s)
	return string.gsub(s, "%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
end

