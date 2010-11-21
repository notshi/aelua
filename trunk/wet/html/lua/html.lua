

local log=require("wetgenes.aelua.log").log

local sys=require("wetgenes.aelua.sys")
local waka=require("wetgenes.waka")
local users=require("wetgenes.aelua.users")

local wet_html=require("wetgenes.html")
local replace=wet_html.replace
local url_esc=wet_html.url_esc

local base_html=require("base.html")


local table=table
local string=string
local math=math
local os=os

local pairs=pairs
local tostring=tostring

module("html")

-----------------------------------------------------------------------------
--
-- load and parse plates.html
--
-----------------------------------------------------------------------------

base_html.import(_M)


