
local wet_html=require("wetgenes.html")
local url_esc=wet_html.url_esc

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_waka=require("wetgenes.waka")
local wet_html=require("wetgenes.html")

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local replace  =wet_string.replace
local serialize=wet_string.serialize



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
local require=require

-- opts
local opts_mods_note=(opts and opts.mods and opts.mods.note) or {}

module("note.comments")
local wetdata=require("data")

--------------------------------------------------------------------------------
--
-- serving flavour can be used to create a subgame of a different flavour
-- make sure we incorporate flavour into the name of our stored data types
--
--------------------------------------------------------------------------------
function kind(srv)
	return "note.comments" -- this note module is site wide, which means so is the comment table
end

--------------------------------------------------------------------------------
--
-- Create a new local entity filled with initial data
--
--------------------------------------------------------------------------------
function create(srv)

	local ent={}
	
	ent.key={kind=kind(srv)} -- we will not know the key id until after we save
	ent.props={}
	
	local p=ent.props
	
	p.created=srv.time
	p.updated=srv.time
	
	p.author="" -- the email of who wrote this comment (can be used to lookup user)
	p.url=""    -- the site url for which this is a comment on, site comments relative to root begin with "/"
	p.group=0   -- the id of our parent or 0 if this is a master comment on a url, -1 if it is a meta cache
	p.type="ok" -- a type string to filter on
				-- ok    - this is a valid comment, display it
				-- spam  - this is pure spam, hidden but not forgotten
				-- meta  - use on fake comments that only contain cached info of other comments

	p.count=0       -- number of replies to this comment (could be good to sort by)
	p.pagecount=0   -- number of pagecomments to this comment (this comment is treated as its own page)

-- track some simple vote numbers, to be enabled later?

	p.good=0 -- number of good content "votes"
	p.spam=0 -- number of spam "votes"
	
	p.media=0 -- an associated data.meta id link, 0 if no media,
				-- so each post can have eg an image associated with it ala 4chan
	
	dat.build_cache(ent) -- this just copies the props across
	
-- these are json only vars
	local c=ent.cache
	
	c.text="" -- this string is the main text of this comment
	c.cache={} -- some cached info of other comments/users etc, 

	return check(srv,ent)
end

--------------------------------------------------------------------------------
--
-- check that entity has initial data and set any missing defaults
-- the second return value is false if this is not a valid entity
--
--------------------------------------------------------------------------------
function check(srv,ent)

	local ok=true

	local c=ent.cache
			
	return ent,ok
end


--------------------------------------------------------------------------------
--
-- manifest a meta comment cache, there is only one of these per url
-- so we can use that as its key
-- most data is kept in its ent.cache.cache table
--
--------------------------------------------------------------------------------
function manifest(srv,url,t)

	local ent
	
	local fill=false
	
	if not ent then
		ent=create(srv)
		ent.key.id=url
		ent=get(srv,ent,t) -- prevent manifest recursion by passing in ent
	end
	
	if not ent then
		ent=create(srv)
		fill=true
	end
	
	if fill then
		ent.key.id=url -- force id which is page name string
		ent.cache.group=-1 -- no group
		ent.cache.id=url -- copy here
		ent.cache.type="meta"
	end
	
	return (check(serv,ent)) -- wrap in () to just return the ent
end

--------------------------------------------------------------------------------
--
-- Save to database
-- this calls check before putting and does not put if check says it is invalid
-- build_props is called so code should always be updating the cache values
--
--------------------------------------------------------------------------------
function put(srv,ent,t)

	t=t or dat -- use transaction?

	local _,ok=check(srv,ent) -- check that this is valid to put
	if not ok then return nil end

	dat.build_props(ent)
	local ks=t.put(ent)
	
	if ks then
		ent.key=dat.keyinfo( ks ) -- update key with new id
		dat.build_cache(ent)
	end

	return ks -- return the keystring which is an absolute name
end


--------------------------------------------------------------------------------
--
-- Load from database, pass in id or entity
-- the props will be copied into the cache
--
--------------------------------------------------------------------------------
function get(srv,id,t)

	if type(id)=="string" then -- auto manifest by url
		return manifest(srv,id,t)
	end
	
	local ent=id
	if type(ent)~="table" then -- get by id
		ent=create(srv)
		ent.key.id=id
	end
	
	t=t or dat -- use transaction?
	
	if not t.get(ent) then return nil end	
	dat.build_cache(ent)
	
	return check(srv,ent)
end

--------------------------------------------------------------------------------
--
-- get - update - put
--
-- f must be a function that changes the entity and returns true on success
-- id can be an id or an entity from which we will get the id
--
--------------------------------------------------------------------------------
function update(srv,id,f)

	if type(id)=="table" then id=id.key.id end -- can turn an entity into an id
		
	for retry=1,10 do
		local mc={}
		local t=dat.begin()
		local e=get(srv,id,t)
		if e then
			what_memcache(srv,e,mc) -- the original values
			e.cache.updated=srv.time -- the function can change this change if it wishes
			if not f(srv,e) then t.rollback() return false end -- hard fail
			check(srv,e) -- keep consistant
			if put(srv,e,t) then -- entity put ok
				if t.commit() then -- success
					what_memcache(srv,e,mc) -- the new values
					fix_memcache(srv,mc) -- change any memcached values we just adjusted
					return e -- return the adjusted entity
				end
			end
		end
		t.rollback() -- undo everything ready to try again
	end
	
end


--------------------------------------------------------------------------------
--
-- given an entity return or update a list of memcache keys we should recalculate
-- this list is a name->bool lookup
--
--------------------------------------------------------------------------------
function what_memcache(srv,ent,mc)
	local mc=mc or {} -- can supply your own result table for merges	
	local c=ent.cache
	
	return mc
end

--------------------------------------------------------------------------------
--
-- fix the memcache items previously produced by what_memcache
-- probably best just to delete them so they will automatically get rebuilt
--
--------------------------------------------------------------------------------
function fix_memcache(srv,mc)
	for n,b in pairs(mc) do
		cache.del(n)
	end
end


--------------------------------------------------------------------------------
--
-- list comments
--
--------------------------------------------------------------------------------
function list(srv,opts,t)
	opts=opts or {} -- stop opts from being nil
	
	t=t or dat -- use transaction?
	
	local q={
		kind=kind(srv),
		limit=opts.limit or 100,
		offset=opts.offset or 0,
	}
	
-- add filters?
	for i,v in ipairs{"author","url","group","type"} do
		if opts[v] then
			q[#q+1]={"filter",v,"==",opts[v]}
		end
	end

-- sort by?
	if opts.sortdate then
		q[#q+1]={"sort","updated", opts.sortdate }
	end
	if opts.csortdate then
		q[#q+1]={"sort","created", opts.csortdate }
	end
	
	local r=t.query(q)

	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
end

--------------------------------------------------------------------------------
--
-- update and return the meta cache
--
--------------------------------------------------------------------------------
function update_meta_cache(srv,url)

	local count=0

-- build meta cache			
	local cs=list(srv,{sortdate="DESC",url=url,group=0}) -- get all comments
	local comments={}
	for i,v in ipairs(cs) do -- and build comment cache
		comments[i]=v.cache
		count=count+1+v.cache.count
	end


-- the comment cache may lose one if multiple people reply at the same time
-- an older cache may get saved, very unlikley but possible
-- url is a string so this manifests if it does not exist

	local meta=update(srv,url,function(srv,e)
	
		e.cache.comments=comments -- save new comment cache
		e.cache.count=count -- a number to sort by
		
		return true
	end)
	return meta
end


-- display comment code
function build_get_comment(srv,tab,c)

	if tab.ret and tab.ret.count then -- counter hax
		tab.ret.count=tab.ret.count+1
	end
	
	local media=""
	if c.media~=0 then
		media=[[<a href="/data/]]..c.media..[["><img src="/thumbcache/460/345/data/]]..c.media..[[" class="wetnote_comment_img" /></a>]]
	end
	
	local plink,purl=users.email_to_profile_link(c.cache.user.email)
	return tab.get([[
<div class="wetnote_comment_div" id="wetnote{id}" >
<div class="wetnote_comment_icon" ><a href="{purl}"><img src="{icon}" width="100" height="100" /></a></div>
<div class="wetnote_comment_head" > #{id} posted by <a href="{purl}">{name}</a> on {time} </div>
<div class="wetnote_comment_text" >{media}{text}</div>
<div class="wetnote_comment_tail" ></div>
</div>
]],{
	media=media,
	text=wet_waka.waka_to_html(c.text,{base_url=tab.url,escape_html=true}),
	author=c.cache.user.email,
	name=c.cache.user.name,
	plink=plink,
	purl=purl or "http://google.com/search?q="..c.cache.user.name,
	time=os.date("%Y-%m-%d %H:%M:%S",c.created),
	id=c.id,
	icon=c.cache.avatar or users.email_to_avatar_url(c.cache.user.email),
	})
end

--------------------------------------------------------------------------------
--
-- post data to this comment url if we have any
-- display comment form at top so you can comment on this post
-- display comments + replies if we have any
-- with reply links so you can reply to these previous comment threads
--
-- pass in get,set,posts,user,sess using the tab table
-- also set tab.url to the url
--
--------------------------------------------------------------------------------
function build(srv,tab)
local function dput(s) put("<div>"..tostring(s).."</div>") end

	local ret={}
	tab.ret=ret
	ret.count=0
	
	local meta
	
	local user=(tab.user and tab.user.cache)
	
	if tab.posts then
	
		if user and tab.posts.wetnote_comment_submit then -- add this comment
		
			local posted
		
			if #tab.posts.wetnote_comment_text > 4096 then
				tab.put([[
				<div class="wetnote_error">
				Sorry but your comment was too long (>4096 chars) to be accepted.
				</div>
				]])
				return
			end
--[[			
			if #tab.posts.wetnote_comment_text <=3 then
				tab.put([-[
				<div class="wetnote_error">
				Sorry but your comment was too short (>3 chars) to be accepted.
				</div>
				]-])
				return
			end
]]			
			if tab.posts.filedata and tab.posts.filedata.size>0 then
			
				if tab.posts.filedata.size>=1000000 then
					tab.put([[
					<div class="wetnote_error">
					Sorry but your upload must not be bigger than 1000000 bytes in size.
					</div>
					]])
					return			
				end
				
				local image=img.get(tab.posts.filedata.data) -- convert to image
				
				if not image then
					tab.put([[
					<div class="wetnote_error">
					Sorry but your upload must be a valid image.
					</div>
					]])
					return
				else
					if image.width>1024 or image.height>1024 then -- resize, keep aspect
						image=img.resize(image,1024,1024,"JPEG") -- resize image
						tab.posts.filedata.data=image.data
						tab.posts.filedata.size=image.size
						tab.posts.filedata.name=tab.posts.filedata.name..".jpg" -- make sure its a jpg
					end
				end
			end
		
			local id=math.floor(tonumber(tab.posts.wetnote_comment_id))
			local e=create(srv)
			local c=e.cache
			
			local title=tab.title-- the title of the page we are commenting upon,can be null
			if title then
				if #title>32 then -- left most 32 chars
					title=title:sub(1,29).."..."
				end
			else
				title=tab.url
				if title then
					if #title>32 then -- right most 32 chars
						title="..."..title:sub(-29)
					end
				end
			end
			if title then -- url escape it
				if #title < 3 then title="this" end
				title=wet_html.esc(title)
			end
			c.cache.user=tab.user.cache
			c.avatar=users.email_to_avatar_url(user.email or "") -- this can be expensive so we cache it
			c.author=tab.user.cache.email
			c.url=tab.url
			c.group=id
			c.text=tab.posts.wetnote_comment_text
			c.title=title
			if tab.posts.filedata and tab.posts.filedata.size>0 then -- got a file
				local dat={}
				dat.id=0
				
				dat.data=tab.posts.filedata and tab.posts.filedata.data
				dat.size=tab.posts.filedata and tab.posts.filedata.size
				dat.name=tab.posts.filedata and tab.posts.filedata.name
				dat.owner=user.email
				
				wetdata.upload(srv,dat)

				c.media=dat.id -- remember id
			end
			
			put(srv,e)
			posted=e
			tab.modified=true -- flag that caller should update cache
			
			if id~=0 then -- this is a comment so apply to master
			
				local rs=list(srv,{sortdate="ASC",url=tab.url,group=id}) -- get all replies
				local replies={}
				for i,v in ipairs(rs) do -- and build reply cache
					replies[i]=v.cache
				end
				
-- the reply cache may lose one if multiple people reply at the same time
-- an older cache may get saved, very unlikley but possible

				update(srv,id,function(srv,e)
					e.cache.replies=replies -- save new reply cache
					e.cache.count=#replies -- a number to sort by
					return true
				end)
				
			else -- this is a master comment
			
				if tab.save_post=="status" then -- we want to save this as user posted status
					tab.user.cache.comment_status=c.text
					users.put(srv,tab.user) -- probably safe?
				end

			end

			meta=update_meta_cache(srv,tab.url)
			ret.count=meta.cache.count

			if posted and posted.cache then -- redirect to our new post
			
				cache.del("kind="..kind(H).."&find=recent&limit="..(50)) -- reset normal recent cache

				if id==0 then
					sys.redirect(srv,tab.url.."?wetnote="..posted.cache.id.."#wetnote"..posted.cache.id)
				else
					sys.redirect(srv,tab.url.."?wetnote="..id.."#wetnote"..id)
				end
				
				return
			end

		end
		
	end

	
-- reply page link
	function get_reply_page(num)
		return tab.get([[
<div class="wetnote_comment_form_div">
<a href="{url}">Reply</a>
</div>]],{
			url=tab.url.."/"..num
		})
	end
	
-- reply form
	function get_reply_form(num)
		if not user then -- must login to reply
			return tab.get([[
<div class="wetnote_comment_form_div">
<a href="#" onclick="$(this).hide(400);$('#wetnote_comment_form_{id}').show(400);return false;" style="{actioncss}">Reply</a>
<div id="wetnote_comment_form_{id}" style="{formcss}"> <a href="{url}">You must login to comment.<br/> Click here to login with twitter/gmail/etc...</a>
</div>
</div>]],{
			url="/dumid/login/?continue="..url_esc(srv.url),
			actioncss=(num==0) and "display:none" or "display:block",
			formcss=(num==0) and "display:block" or "display:none",
			id=num,
		})
		end
		local upload=""
		if tab.image then
			upload=[[<div><input type="file" name="filedata" style="margin-left:110px;width:500px;" /></div>]]
		end
		local post_text="Express your important opinion"
		if num==0 then
			if tab.post_text then post_text=tab.post_text end
		else
			if tab.reply_text then reply_text=tab.reply_text end
		end
		local plink,purl=users.email_to_profile_link(user.email or "")
		return tab.get([[
<div class="wetnote_comment_form_div">
<a href="#" onclick="$(this).hide(400);$('#wetnote_comment_form_{id}').show(400);return false;" style="{actioncss}">Reply</a>
<form class="wetnote_comment_form" name="wetnote_comment_form" id="wetnote_comment_form_{id}" action="" method="post" enctype="multipart/form-data" style="{formcss}">
	<div class="wetnote_comment_icon" ><a href="{purl}"><img src="{icon}" width="100" height="100" /></a></div>
	<textarea class="wetnote_comment_form_text" name="wetnote_comment_text"></textarea>
	<input name="wetnote_comment_id" type="hidden" value="{id}"></input>
	{upload}
	<input class="wetnote_comment_post" name="wetnote_comment_submit" type="submit" value="{post_text}"></input>
</form>
</div>
]],{
		actioncss=(num==0) and "display:none" or "display:block",
		formcss=(num==0) and "display:block" or "display:none",
		author=user.email or "",
		name=user.name or "",
		plink=plink,
		purl=purl or "http://google.com/search?q="..(user.name or ""),
		time=os.date("%Y-%m-%d %H:%M:%S"),
		id=num,
		icon=users.email_to_avatar_url(user.email or ""),
		upload=upload,
		post_text=post_text,
		})
	end
		
-- the meta will contain the cache of everything, we may already have it due to updates	
	if not meta then
		meta=manifest(srv,tab.url)
	end

	tab.put([[<div class="wetnote_main">]])
	tab.put([[<div class="wetnote_main2">]])
	
	tab.put([[<div class="wetnote_comments">]])
	
	tab.put([[<div class="wetnote_comment_form_head"></div>]])
	tab.put(get_reply_form(0))
	tab.put([[<div class="wetnote_comment_form_tail"></div>]])

-- get all top level comments
--	local cs=list(srv,{sortdate="DESC",url=tab.url,group=0})
	local cs=meta.cache.comments or {}
	
	if tab.toponly then -- just display a top comment field
	
		for i,c in ipairs(cs) do
--			if i>=1 then break end -- 5 only?
			tab.put(build_get_comment(srv,tab,c)) -- main comment
			tab.put([[
<div class="wetnote_reply_div">
]])

--log(" pagecount of " .. tostring(c.pagecount) )

			if c.pagecount > 1 then
					tab.put([[
<div><a href="{url}">View {pagecount} comments.</a></div>
]],{
	pagecount=c.pagecount,
	url=tab.url.."/"..c.id,
	})
			end

			local rs=c.pagecomments or {} -- list(srv,{sortdate="ASC",url=tab.url,group=c.id}) -- replies

			for i=1,1,-1  do -- put last 5? 1? cached comments on page if we have them
				local c=rs[i]
				if c then
					tab.put(build_get_comment(srv,tab,c))
				end
			end
			
			tab.put(get_reply_page(c.id))

			tab.put([[
</div>
]])
		end
	
	else
		
		for i,c in ipairs(cs) do
	

	--		local c=v.cache
			tab.put(build_get_comment(srv,tab,c)) -- main comment
					
			tab.put([[
<div class="wetnote_reply_div">
]])

			local rs=c.replies or {} -- list(srv,{sortdate="ASC",url=tab.url,group=c.id}) -- replies
			
			local hide=#rs-5
			if hide<0 then hide=0 end -- nothing to hide
			local hide_state="show"
			
			for i,c in ipairs(rs) do				
	--			local c=v.cache
				if i<=hide then -- hide this one
					if hide_state=="show" then
						hide_state="hide"
						tab.put([[
<div class="wetnote_comment_hide_div">
<a href="#" onclick="$(this).hide(400);$('#wetnote_comment_hide_{id}').show(400);return false;">Show {hide} hidden comments</a>
<div id="wetnote_comment_hide_{id}" style="display:none">
]],{
		id=c.id,
		hide=hide,
		})
					end
				else
					if hide_state=="hide" then
						hide_state="show"
						tab.put([[</div></div>]])
					end
				end
				
				tab.put(build_get_comment(srv,tab,c))
				
			end
			
			tab.put(get_reply_form(c.id))

			tab.put([[
</div>
]])
		end
	end
	
	tab.put([[</div>]])
	
	
	if tab.toponly then
		r={}
	else
		local r=get_recent(srv,50)
		tab.put([[
	<div class="wetnote_ticker">{text}</div>
	]],	{
			text=recent_to_html(srv,r),
		})
	end
	
	
	tab.put([[</div>]])
	tab.put([[</div>]])

	tab.put([[
<script language="javascript" type="text/javascript">
	$(function(){
		$(".wetnote_comment_text a").autoembedlink({width:460,height:345});
	});
</script>	
	]])

	return ret
end


--------------------------------------------------------------------------------
--
-- get num recent comments, cached so this is very fuzzy
--
--------------------------------------------------------------------------------
function get_recent(srv,num)

	-- a unique keyname for this query
	local cachekey="kind="..kind(H).."&find=recent&limit="..num
	
	local r=cache.get(cachekey) -- do we already know the answer?

	if r then -- we cached the answer
		return json.decode(r) -- turn back into data
	end

	local recent=list(srv,{limit=num,type="ok",csortdate="DESC"})

	cache.put(cachekey,json.encode(recent),2*60) -- save this in cache for 2 minutes
	
	return recent
end



-----------------------------------------------------------------------------
--
-- turn a number of seconds into a rough duration
--
-----------------------------------------------------------------------------
local function rough_english_duration(t)
	t=math.floor(t)
	if t>=2*365*24*60*60 then
		return math.floor(t/(365*24*60*60)).." years"
	elseif t>=2*30*24*60*60 then
		return math.floor(t/(30*24*60*60)).." months" -- approximate months
	elseif t>=2*7*24*60*60 then
		return math.floor(t/(7*24*60*60)).." weeks"
	elseif t>=2*24*60*60 then
		return math.floor(t/(24*60*60)).." days"
	elseif t>=2*60*60 then
		return math.floor(t/(60*60)).." hours"
	elseif t>=2*60 then
		return math.floor(t/(60)).." minutes"
	elseif t>=2 then
		return t.." seconds"
	elseif t==1 then
		return "1 second"
	else
		return "0 seconds"
	end
end

--------------------------------------------------------------------------------
--
-- recent to html
--
--------------------------------------------------------------------------------
function recent_to_html(srv,tab)

	local t={}
	local put=function(str,tab)
		t[#t+1]=replace(str,tab)
	end

	for i,v in ipairs(tab) do
		local c=v.cache
		
		local link=c.url.."#wetnote"
		if c.group==0 then
			link=link..c.id -- link to main comment
		else
			link=link..c.group -- link to what we are commenting on
		end
		if link:sub(1,1)=="/" then link=srv.url_domain..link end -- and make it absolute
		
		local plink,purl=users.email_to_profile_link(c.cache.user.email)

		put([[
<div class="wetnote_tick">
{time} ago <a href="{purl}">{name}</a> commented on <br/> <a href="{link}">{title}</a>
</div>
]],{
		name=c.cache.user.name,
		time=rough_english_duration(os.time()-c.created),
		title=c.title or c.url,
		link=link,
		purl=purl or "http://google.com/search?q="..c.cache.user.name,
	})
		
	end

	
	return table.concat(t)
end


