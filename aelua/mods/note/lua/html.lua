
local sys=require("wetgenes.aelua.sys")
local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local html=require("html")

local setmetatable=setmetatable
local tostring=tostring

local os=os

module("note.html")

setmetatable(_M,{__index=html}) -- use a meta table to also return html base 



-----------------------------------------------------------------------------
--
-- overload footer
--
-----------------------------------------------------------------------------
footer=function(d)
	d.mod_name="note"
	d.mod_link="http://boot-str.appspot.com/about/mod/note"
	return html.footer(d)
end



-----------------------------------------------------------------------------
--
-- atom wrappers
--
-----------------------------------------------------------------------------
note_atom_head=function(d)
	return replace([[<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">

	<title>{title}</title>
	<link rel="self" href="{srv.url_base}.atom"/>
	<updated>{updated}</updated>
	<author>
		<name>{author_name}</name>
	</author>
	<id>{srv.url_base}.atom</id>
]],d)

end

note_atom_foot=function(d)
	return replace([[</feed>
]],d)

end
note_atom_item=function(d)
	d.pubdate=(os.date("%Y-%m-%dT%H:%M:%SZ",d.it.created))
	d.id=d.link
	return replace([[
	<entry>
		<title type="text">{title}</title>
		<link href="{link}"/>
		<id>{id}</id>
		<updated>{pubdate}</updated>
		<content type="html">{text}</content>
	</entry>
]],d)

end

