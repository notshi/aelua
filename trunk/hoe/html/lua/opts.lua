
local os=os
local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize

module("opts")

mods={}

mods.console={}

mods.console.input=
[[
local srv=(...)
local hoe=require("hoe")
local con=require("hoe.con")
local H=hoe.create(srv)

print(con.help(H))
]]


