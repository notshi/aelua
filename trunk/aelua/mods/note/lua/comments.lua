
local wet_html=require("wetgenes.html")

local sys=require("wetgenes.aelua.sys")

local json=require("json")
local dat=require("wetgenes.aelua.data")

local users=require("wetgenes.aelua.users")

local fetch=require("wetgenes.aelua.fetch")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
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


-- opts
local opts_mods_note=(opts and opts.mods and opts.mods.note) or {}

module("note.comments")

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
				-- ok   - this is a valid comment, display it
				-- spam - this is pure spam, hidden but not forgotten
				-- meta - use on fake comments that only contain cached info of other comments

	p.replies=0 -- number of replies to this comment (could be good to sort by)

-- track some simple vote numbers, to be enabled later?

	p.good=0 -- number of good content "votes"
	p.spam=0 -- number of spam "votes"
	
	p.media=0 -- an associated media id link, 0 if no media
	
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
function manifest(srv,url)

	local ent
	
	local fill=false
	
	if not ent then
		ent=get(srv,url)
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
	local r=t.query(q)

	for i=1,#r.list do local v=r.list[i]
		dat.build_cache(v)
	end

	return r.list
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
function do_post(srv,tab)
local function dput(s) put("<div>"..tostring(s).."</div>") end

	local meta=manifest(srv,tab.url)
	
	local user=(tab.user and tab.user.cache) or {}
	
	if tab.posts then
		if tab.posts.wetnote_comment_submit then -- add this comment
		
			local id=math.floor(tonumber(tab.posts.wetnote_comment_id))
			local e=create(srv)
			local c=e.cache
			
			c.cache.user=tab.user.cache
			c.author=tab.user.cache.email
			c.url=tab.url
			c.group=id
			c.text=tab.posts.wetnote_comment_text
			
			put(srv,e)
			
		end
		
--		for i,v in pairs(tab.posts) do
--			tab.put("<div>"..i.."="..v.."</div>")
--		end

	end

	function get_reply_form(num)
		local plink,purl=users.email_to_profile_link(user.email or "")
		return tab.get([[
<div class="wetnote_comment_form_div">
<a href="#" onclick="$(this).hide(400);$('#wetnote_comment_form_{id}').show(400);return false;" style="{actioncss}">Click here to reply.</a>
<form class="wetnote_comment_form" name="wetnote_comment_form" action="" method="post" enctype="multipart/form-data" style="{formcss}">
	<div class="wetnote_comment_side">
		<div class="wetnote_comment_icon" ><a href="{purl}"><img src="{icon}" width="100" height="100" /></a></div>
		<input class="wetnote_comment_post" name="wetnote_comment_submit" type="submit" value="comment"></input>
	</div>
	<div class="wetnote_comment_main">
		<textarea class="wetnote_comment_text" name="wetnote_comment_text"></textarea>
		<input name="wetnote_comment_id" type="hidden" value="{id}"></input>
	</div>
</form>
</div>
]],{
		actioncss="display:block",
		formcss="display:block",
		author=user.email or "",
		name=user.name or "",
		plink=plink,
		purl=purl or "http://google.com/search?q="..(user.name or ""),
		time=os.date("%Y-%m-%d %H:%M:%S"),
		id=0,
		icon=users.email_to_avatar_url(user.email or ""),
		})
	end
	tab.put(get_reply_form(0))

-- get all top level comments
	local cs=list(srv,{sortdate="DESC",url=tab.url,group=0})
	
--	tab.put([[<div>{count} comments</div>]],{count=#cs})

	for i,v in ipairs(cs) do
		local c=v.cache
		local plink,purl=users.email_to_profile_link(c.cache.user.email)
		tab.put([[
<div class="wetnote_comment_div" >
<div class="wetnote_comment_icon" ><a href="{purl}"><img src="{icon}" width="100" height="100" /></a></div>
<div class="wetnote_comment_text" >
<div class="wetnote_comment_head" > #{id} posted by <a href="{purl}">{name}</a> on {time} </div>
{text}
<div class="wetnote_comment_tail" ></div>
</div>
</div>
]],{
	text=c.text,
	author=c.cache.user.email,
	name=c.cache.user.name,
	plink=plink,
	purl=purl or "http://google.com/search?q="..c.cache.user.name,
	time=os.date("%Y-%m-%d %H:%M:%S",c.created),
	id=c.id,
	icon=users.email_to_avatar_url(c.cache.user.email),
	})

		local rs=list(srv,{sortdate="ASC",url=tab.url,group=c.id})
--		tab.put([[<div>{count} replys</div>]],{count=#rs})

		local hide=#rs-5
		if hide<0 then hide=0 end -- nothing to hide
		local hide_state="show"
		
		for i,v in ipairs(rs) do
			local c=v.cache
			if i<=hide then -- hide this one
				if hide_state=="show" then
					hide_state="hide"
					tab.put([[
<div class="wetnote_comment_hide_div">
<a href="#" onclick="$(this).hide(400);$('#wetnote_comment_hide_{id}').show(400);return false;">Click here to show {hide} hidden comments.</a>
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
			local plink,purl=users.email_to_profile_link(c.cache.user.email)
			tab.put([[
<div class="wetnote_reply_div" >
<div class="wetnote_reply_icon" ><a href="{purl}"><img src="{icon}" width="100" height="100" /></a></div>
<div class="wetnote_reply_text" >
<div class="wetnote_reply_head" > #{id} posted by <a href="{purl}">{name}</a> on {time} </div>
{text}
<div class="wetnote_reply_tail" ></div>
</div>
</div>
]],{
	text=c.text,
	author=c.cache.user.email,
	name=c.cache.user.name,
	plink=plink,
	purl=purl or "http://google.com/search?q="..c.cache.user.name,
	time=os.date("%Y-%m-%d %H:%M:%S",c.created),
	id=c.id,
	icon=users.email_to_avatar_url(c.cache.user.email),
	})
		end
		
		tab.put(get_reply_form(c.id))

	end
	

end


