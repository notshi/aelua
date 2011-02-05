#!/usr/bin/lua


local edge="--Machine generated data. Read between the lines, but do not edit."
local fname="html/lua/opts.lua"
local data=""

local fp=assert(io.open(fname,"r"))
local text=fp:read("*all")
fp:close()

local b1,b2

b1= string.find(text, edge , 1 , true)
b2= string.find(text, edge , b1+#edge , true)+#edge-1

assert( b1 and b2 , "Failed to find block of data to bump" )

--20110204.1
local t=os.time()
local t1,t2=math.modf(t/(24*60*60))
local t3=math.floor(t2*100)/100
local t4=tonumber(os.date("%Y%m%d",t))

data="bootstrapp_version="..(t4+t3)

data=edge.."\n"..data.."\n"..edge

print(data)

local fp=assert(io.open(fname,"w"))
fp:write( text:sub(1,b1-1) )
fp:write( data )
fp:write( text:sub(b2+1) )
fp:close()
