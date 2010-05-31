

-- create a global table for keeping templates in
html=html or {}


local string=string
local type=type

local html=html




module("wetgenes.html")






-----------------------------------------------------------------------------
--
-- replace tags in {} in the string with data provided
-- allow sub table look up with a.b notation in the name
--
-----------------------------------------------------------------------------
function replace(a,d)

return (string.gsub( a , "{(.-)}" , function(a)

	local f
	
	f=function(a,d) -- look up a in table d
	
		if string.len(a)>128 then return a end -- do not even try with large strings
	
		if d[a] then return d[a] end -- simple find
		
		local a1,a2=string.find(a, "%.") -- try and split on first "."
		if not a1 then return a end -- didnt find a dot so return look up
		
		a1=string.sub(a,1,a1-1) -- the bit before the .
		a2=string.sub(a,a2+1) -- the bit after the .
		
		local dd=d[a1] -- use the bit befre the dot to find the sub table
		
		if type(dd)=="table" then -- check we got a table
			return f(a2,dd) -- tail call this function
		end
		
		return a -- couldnt find anything return input string
	end

	return f(a,d)
	
end ))

end



-----------------------------------------------------------------------------
--
-- build a string from a template,  with a table to be used as its environment
--
-- this environment may get junked on slightly by the script :)
-- so possibly best to use a new one for each call
-- or at least make sure that you are setting or clearing the important parts
--
-----------------------------------------------------------------------------
get=function(src,env)

	if html[src] then src=html[src] end
	
	if type(src)=="function" then return src(env or {}) end
	
	if type(src)=="string" and env then return replace(src,env) end

	return tostring(src)
end

