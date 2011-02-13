
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

--local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local d_sess =require("dumid.sess")

-- require all the module sub parts
local html=require("console.html")



local math=math
local string=string
local table=table

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type
local pcall=pcall
local loadstring=loadstring


--
-- Which can be overeiden in the global table opts
--
local opts_mods_console={}
if opts and opts.mods and opts.mods.console then opts_mods_console=opts.mods.console end

module("console")

-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-- do not cache the srv param localy, make sure it cascades around
--
-----------------------------------------------------------------------------
function serv(srv)
local sess,user=d_sess.get_viewer_session(srv)

	if not( user and user.cache and user.cache.admin ) then -- adminfail
		return false
	end

	local function put(a,b)
		b=b or {}
		b.srv=srv
		srv.put(wet_html.get(html,a,b))
	end

	if not ( user and user.cache.admin ) then -- error must be admin
		srv.set_mimetype("text/html")
		put("header",{})
		put("error_need_admin",{})
		put("footer",{})
		return
	end
	
	if post(srv) then return end -- post handled everything

	local slash=srv.url_slash[ srv.url_slash_idx ]
--	if slash=="image" then return image(srv) end -- image request
		


	srv.set_mimetype("text/html")
	put("header",{user=user})
	
	put("console_form",{output=srv.posts.output or "",input=srv.posts.input or opts_mods_console.input or ""})
	
	put("footer",{})
	
end


-----------------------------------------------------------------------------
--
-- the post function, looks for post params and handles them
--
-----------------------------------------------------------------------------
function post(srv)

	if srv.posts.input then -- run it
	
		local b,f,r
		local head=
[[local _r={} local function print(s) _r[#_r+1]=tostring(s) end

]]
		local tail=
[[

return table.concat(_r,"\n")

]]
		f,r=loadstring( head..srv.posts.input..tail )
		
		if f then
			b,r=pcall( f , srv )
		end
		
		srv.posts.output=srv.posts.output.."-- \n"..tostring(r)
	
	end

	return false -- keep going anyway

end

