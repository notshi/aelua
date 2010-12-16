
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local replace=wet_string.replace
local macro_replace=wet_string.macro_replace
local trim=wet_string.trim
local str_split=wet_string.str_split
local serialize=wet_string.serialize

local wet_waka=require("wetgenes.waka")

-- require all the module sub parts
local html=require("data.html")
local meta=require("data.meta")
local file=require("data.file")

local comments=require("note.comments")


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

-- our options
local opts_mods_blog={} or ( opts and opts.mods and opts.mods.blog )


local LAYER_PUBLISHED = 0
local LAYER_DRAFT     = 1
local LAYER_SHADOW    = 2

module("data")

-----------------------------------------------------------------------------
--
-- create get and put wrapper functions
--
-----------------------------------------------------------------------------
local function make_get_put(srv)
	local get=function(a,b)
		b=b or {}
		b.srv=srv
		return wet_html.get(html,a,b)
	end
	local put=function(a,b)
		srv.put(get(a,b))
	end
	return get,put
end


-----------------------------------------------------------------------------
--
-- the serv function, where the action happens.
--
-----------------------------------------------------------------------------
function serv(srv)
	if srv.url_slash[srv.url_slash_idx+0]=="" and srv.url_slash[srv.url_slash_idx+1]=="admin" then
--		return serv_admin(srv)
	end
	
local sess,user=users.get_viewer_session(srv)
local get,put=make_get_put(srv)

	local num=math.floor( tonumber( srv.url_slash[srv.url_slash_idx+0] or 0 ) or 0 )
	
	if num~=0 and tostring(num)==srv.url_slash[srv.url_slash_idx+0] then --got us an id
	
		local em=meta.get(srv,num)
		
		if em then -- got a data file to serv
		
			local ef=file.get(srv,em.cache.filekey)
			
			srv.set_mimetype(em.cache.mimetype)
			
			srv.set_header("Cache-Control","public") -- allow caching of page
			
			while true do
			
				if ef then
				
					srv.put(ef.cache.data)
					
					if ef.cache.nextkey==0 then return end -- last chunk
					
					ef=file.get(srv,ef.cache.nextkey) -- read next part
					
				else
					return -- error
				end
			end
			
		end
		
	end
	
	
	
-- upload / list for admin

	srv.set_mimetype("text/html; charset=UTF-8")
	put("header",{title="data : ",
		H={sess=sess,user=user},
		})
	
--	put(tostring(user and user.cache),{H=H})
	if user and user.cache and user.cache.admin then -- admin
	
		local posts={} -- remove any gunk from the posts input
		if srv.method=="POST" and srv.headers.Referer and srv.headers.Referer==srv.url then
			for i,v in pairs(srv.posts) do
				posts[i]=v
			end
		end
		
		posts["filedata"]=srv.uploads["filedata"] -- uploaded file
				
		for i,v in pairs({"filename","mimetype","submit"}) do
			if posts[v] then posts[v]=trim(posts[v]) end
		end
		for i,v in pairs({"dataid"}) do
			if posts[v] then posts[v]=tonumber(posts[v]) end
		end
	
--		put(tostring(posts).."<br/>",{H=H})
		
		
		if posts.submit=="Upload" then
		
			local dat={}
			dat.id=posts.dataid
			
			dat.data=posts.filedata and posts.filedata.data
			dat.size=posts.filedata and posts.filedata.size
			dat.name=posts.filedata and posts.filedata.name
			
			if posts.mimetype and posts.mimetype~="" then dat.mimetype=posts.mimetype end
			if posts.filename and posts.filename~="" then dat.name=posts.filename end
			
			upload(srv,dat)
			
		end
		
--		put("<img src=\"/data{pubname}\" />",{H=H,pubname=pubname})
			
		put("data_upload_form",{H=H})
		
		local t=meta.list(srv,{sort="usedate"})
		
		for i,v in ipairs(t) do
		
			put("data_list_item",{H=H,it=v})
		
		end
		
	end
	
	put("footer")
	
end


-----------------------------------------------------------------------------
--
-- upload a file to the database (ie a file upload) returns data id,entity,url etc
-- so it can now be displayed if it was a successful upload
--
-- incoming requirements are
--
-- data = the data of the file
-- size = the size of the file
-- name = the name of the file
-- owner = file owner, defaults to user.cache.email
--
-- optional parts are
--
-- id = numerical datakey, pass in 0 or nil to create a new one, otherwise we update the given
-- mimetype = mimetype to use when serving, we try to guess this from the name if not supplied
--
-- return values are
--
-- ent = the meta entity which we created / updated
-- id = the numerical datakey
-- url = the url we can access this file at, relative to this server base so begins with "/"
--
-----------------------------------------------------------------------------
function upload(srv,dat)

local em
local emc

	if ( not dat.id ) or dat.id==0 then -- a new file
	
		em=meta.create(srv)
		emc=em.cache
		dat.id=emc.id -- new id
	
	else -- editing an old file
	
		em=meta.get(srv,dat.id)
		if not em then return end -- failed to get an entity to update
		
		emc=em.cache

	end
	
	dat.ent=em
			
	if dat.data then -- got a file to create

		file.delete(srv,emc.filekey) -- remove any old file data
		
		emc.size=dat.size
		emc.owner=dat.owner
		
		if (not dat.mimetype) or (dat.mimetype=="") then
		
			local l3=dat.name:sub(-3):lower()
			local l4=dat.name:sub(-4):lower()
			
			if l3=="jpg" or l4=="jpeg" then
			
				emc.mimetype="image/jpeg"
				
			elseif l3=="png" then
			
				emc.mimetype="image/png"
				
			elseif l3=="gif" then
			
				emc.mimetype="image/gif"
				
			elseif l3=="txt" then
			
				emc.mimetype="text/plain"
				
			elseif l3=="css" then
			
				emc.mimetype="text/css"
				
			elseif l3=="htm" or l4=="html" then
			
				emc.mimetype="text/html"
				
			else
			
				emc.mimetype="application/octet-stream"
				
			end
			
		else
			emc.mimetype=dat.mimetype
		end
						
		meta.put(srv,em)  -- write once to get an id for the meta
		emc=em.cache
		
		local dd=sys.bytes_split(dat.data,1000*1000) -- need smaller 1meg chunks
		
		for i,v in ipairs(dd) do
		
			v.ef=file.create(srv)
			local efc=v.ef.cache
			
			efc.size=v.size
			
			efc.metakey=emc.id -- the meta id				
			file.put(srv,v.ef) -- save this data, to get an id
			efc=v.ef.cache
			
			if i==1 then
				emc.filekey=efc.id -- remember the id, of the first chunk only
			end
			
		end
		
-- write the real data this time and save the next/prev keys

		for i,v in ipairs(dd) do
		
			local efc=v.ef.cache
			
			efc.data=v.data
			
			if dd[i-1] then
				if dd[i-1].ef then
					efc.prevkey=dd[i-1].ef.cache.id
				end
			end

			if dd[i+1] then
				efc.nextkey=dd[i+1].ef.cache.id
			end
			
			file.put(srv,v.ef) -- save the data, for real
		end
	end
			
	if dat.pubname then
		emc.pubname=dat.pubname
	else
		emc.pubname="/"..emc.id .."/".. dat.name -- default url
	end
	meta.put(srv,em)  -- save the meta
	emc=em.cache
	
-- output data

	dat.url="/data/"..emc.pubname -- where to reference this file

	return dat
end
