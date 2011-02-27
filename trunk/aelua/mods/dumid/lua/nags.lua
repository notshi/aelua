
local json=require("json")

local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local fetch=require("wetgenes.aelua.fetch")
local sys=require("wetgenes.aelua.sys")


local os=os
local string=string
local math=math

local tostring=tostring
local type=type
local ipairs=ipairs
local require=require

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

--------------------------------------------------------------------------------
--
-- Time to bite the bullet and clean up the session handling
-- so I can link users together for merged profiles
-- unfortunately this was one of the early bits of code so was
-- designed before I got the hange of using googles datastore
-- in fact it was my first use.
--
-- I hope I do not break anything :)
--
--------------------------------------------------------------------------------

module("dumid.nags")
local d_sess=require("dumid.sess")
local d_users=require("dumid.users")

-----------------------------------------------------------------------------
--
-- add some nagging info for printing at the top of each page from now on
-- 
-----------------------------------------------------------------------------
function save(srv,sess,nag)

	nag.time=os.time()
	nag.blanket=tostring(math.random(10000,99999)) -- need a random security number but "random" isnt a big issue
	
	d_sess.update(srv,sess,function(srv,sess)
		local c=sess.cache
		c.nags[nag.id]=nag
		return true
	end)
end

-----------------------------------------------------------------------------
--
-- remove some nagging info
-- 
-----------------------------------------------------------------------------
function delete(srv,sess,nag)
	d_sess.update(srv,sess,function(srv,sess)
		local c=sess.cache
		c.nags[nag.id]=nil
		return true
	end)
end

-----------------------------------------------------------------------------
--
-- clear all current nags
-- 
-----------------------------------------------------------------------------
function clear(srv,sess)
	d_sess.update(srv,sess,function(srv,sess)
		local c=sess.cache
		c.nags={}
		return true
	end)
end

-----------------------------------------------------------------------------
--
-- render nags to html and return them
-- 
-----------------------------------------------------------------------------
function render(srv,sess)
	if not sess then return nil end
	
	local c=sess.cache
	
	if c.nags.note then
		local s=""
		n=c.nags.note
		
		n.blanket=n.blanket or ""
		s=s..n.c140
		
		local twatit="http://twitter.com/home?status="..wet_string.url_encode(n.c140)
		local dellit="/dumid/nag?nag="..n.id.."&blanket="..n.blanket
		local dellit_and_twatit=dellit.."&continue="..wet_string.url_encode(twatit)
		local dellit_and_continue=dellit.."&continue="..wet_string.url_encode(srv.url)
		s=[[
<div class="aelua_nag">Post "<a target="_BLANK" href="]]..dellit_and_twatit..[[">]]..n.c140..[[</a>" to twitter! or
<a href="]]..dellit_and_continue..[[">Cancel!</a></div>
]]
		return "<div class=\"aelua_nags\">"..s.."</div>"
	end

end
