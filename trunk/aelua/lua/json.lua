
-- use wetjson? or possibly a lowlevel json lib if available

local wetjson=require("wetjson")

module("json")

null  =wetjson.null
encode=wetjson.encode
decode=wetjson.decode

