
--
-- time and relative dimensions in space
--
-- a lua library for manipulating time and space
-- pure lua by default and opengl in flavour
--
-- recoil in terror as we use two glyph names to describe table structures
--
-- v# vector [#]
-- m# matrix [#][#]
-- q4 quaternion (yeah its just a repackaged v4)
--
-- each class is a table of # values [1] to [#] , just access them directly
-- they are number streams formated the same way as opengl
-- metatables are used to provide advanced functionality


local math=require("math")
local table=require("table")
local string=require("string")

local getmetatable=getmetatable
local setmetatable=setmetatable
local type=type
local pairs=pairs
local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local require=require


module(...)
local _M=require(...) -- do not rely on any side effects of module

-- a metatable typeof function
mtype_lookup=mtype_lookup or {}
function mtype(it)
	return mtype_lookup[getmetatable(it)] or type(it)
end

-- dumb class inheritance metatable
local function class(name,...)

	local tab=_M[name] or {} -- use old or create new?
	local sub={...} -- possibly multiple sub classes

	if #sub>0 then -- inherit?
		for idx=#sub,1,-1 do -- reverse sub class order, so the ones to the left overwrite the ones on the right
			for i,v in pairs(sub[idx]) do tab[i]=v end -- each subclass overwrites all values
		end
	end

	tab.__index=tab -- this metatable is its own index

	mtype_lookup[name]=tab -- classtype metatable lookup
	mtype_lookup[tab]=name -- tab->name or name->tab

	_M[name]=tab
	return tab
end



class("array")

function array.__tostring(it) -- these classes are all just arrays of numbers
	local t={}
	t[#t+1]=mtype(it)
	t[#t+1]="{"
	for i=1,#it do
		t[#t+1]=tostring(it.i)
		if i~=#t then t[#t+1]=", " end
	end
	t[#t+1]="}"
	return table.concat(t)
end

function array.set(it,...)
	local n=1
	for i,v in ipairs{...} do
		if not it[n] then return it end -- got all the data we need
		if type(v)=="number" then
			it[n]=v
			n=n+1
		else
			for ii,vv in ipairs(v) do -- allow one depth of tables
				it[n]=vv
				n=n+1
			end
		end
	end
	return it
end


class("m2",array)
function m2.new(...) return setmetatable({0,0,0,0},m2):set(...) end

class("m3",m2)
function m3.new(...) return setmetatable({0,0,0,0,0,0,0,0,0},m3):set(...) end

class("m4",m3)
function m4.new(...) return setmetatable({0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},m4):set(...) end



class("v2",array)
function v2.new(...) return setmetatable({0,0},v2):set(...) end

class("v3",v2)
function v3.new(...) return setmetatable({0,0,0},v3):set(...) end

class("v4",v3)
function v4.new(...) return setmetatable({0,0,0,0},v4):set(...) end



class("q4",v4)
function q4.new(...) return setmetatable({0,0,0,0},q4):set(...) end


