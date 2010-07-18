
--
-- Some cgilua helper functions
--

local wet
local cgilua=cgilua

local string=string
local table=table

local type=type
local pairs=pairs
local setfenv=setfenv



module("wetgenes.cgilua")
wet=_M -- wet should point to this module

-----------------------------------------------------------------------------
--
-- wrap everything
--
-----------------------------------------------------------------------------
function setup() -- call setup once to get a global wet cgilua wrapper for this request

local _setup={}
setfenv(1, _setup)

-----------------------------------------------------------------------------
--
-- print a debug string somewhere useful
--
-----------------------------------------------------------------------------
dbg=function(s)
	cgilua.errorlog(s)
	if not headers_sent then 
		contentheader ("text", "html")
	end
	cgilua.put(s)
end


-----------------------------------------------------------------------------
--
-- Build some always useful information about this reuest
--
-----------------------------------------------------------------------------

path=cgilua.servervariable("PATH_INFO")

server=cgilua.servervariable("SERVER_NAME")

query=cgilua.servervariable("QUERY_STRING")

ip=cgilua.servervariable("REMOTE_ADDR")
ipnum=wet.misc.ipstr_to_number(ip)

url="http://"..server..path

if query and query~="" then url=url.."?"..query end

slash=wet.misc.str_split("/",cgilua.script_vpath)
if slash[1] then table.remove(slash,1) end -- first is always ""

-- url is now probably correct if we need to redirect to ourselves


-- the lua query/post are dangerous as they may contain tables...
-- this creates safe copies that are all strings

gets={}

for i,v in pairs(cgilua.QUERY) do

	if type(i)=="string" and type(v)=="string" then

		gets[i]=v

	end
end

posts={}

for i,v in pairs(cgilua.POST) do

	if type(i)=="string" and type(v)=="string" then

		posts[i]=v

	end
end

json=nil

if gets.fmt=="json" or posts.fmt=="json" then -- a special json request, start building the return

	json={}
	json.doups={}

end

-----------------------------------------------------------------------------
--
-- Set content type and remember headers have been sent
--
-----------------------------------------------------------------------------
headers_sent=false

function contentheader(type, subtype)

	if headers_sent then return end -- so this is safe to call multiple times
	
	headers_sent=true -- flag
	
	cgilua.contentheader(type, subtype)

end


-----------------------------------------------------------------------------
--
-- redirect
-- eiher with headers or throw out some javascript if that is too late
--
-----------------------------------------------------------------------------
function redirect(url)

	if headers_sent then

		cgilua.put([[<script type="text/javascript"> window.location = ]]..string.format("%q",url)..[[; </script>]])

	else

		cgilua.redirect(url)

	end

end


-----------------------------------------------------------------------------
--
-- the above functions live in this wrapper
--
-----------------------------------------------------------------------------
return _setup
