
--
-- time and relative dimensions in space
--
-- a lua library for manipulating time and space
-- pure lua by default and opengl in flavour
--
-- recoil in terror as we use two glyph names to describe structures
-- whilst typing in random strings of numbers that may or may not contain tyops
--
-- v# vector [#]
-- m# matrix [#][#]
-- q4 quaternion (yeah its just a repackaged v4)
--
-- each class is a table of # values [1] to [#] , just access them directly
-- they are number streams formated the same way as opengl (row-major)
-- metatables are used to provide advanced functionality


local math=require("math")
local table=require("table")
local string=require("string")

local unpack=unpack
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
		t[#t+1]=tostring(it[i])
		if i~=#it then t[#t+1]=", " end
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
function m2.determinant(it)
	return	 ( it[ 1 ]*it[ 2+2 ] )
			+( it[ 2 ]*it[ 2+1 ] )
			-( it[ 1 ]*it[ 2+1 ] )
			-( it[ 2 ]*it[ 2+1 ] )
end
function m2.transpose(it)
	return	 it[1],it[2+1], it[2],it[2+2]
end
function m2.minor_xy(it,x,y)
	local t={}
	for ix=1,2 do
		for iy=1,2 do
			if (ix~=x) and (iy~=y) then
				t[#t+1]=it(ix+((iy-1)*2))
			end
		end
	end
	return t[1]
end
function m2.cofactor(it)
	local t={}
	for ix=1,2 do
		for iy=1,2 do
			if (ix~=x) and (iy~=y) then
				t[#t+1]=m2.minor_xy(it,ix,iy)
				if ((ix+iy)%2)==1 then t[#t]=-t[#t] end
			end
		end
	end
	return unpack(t)
end
function m2.adjugate(it)
	return m2.transpose{m2.cofactor(it)}
end
function m2.scale(it,s)
	return it[1]*s,it[2]*s, it[2+1]*s,it[2+2]*s
end
function m2.inverse(it)
	local ood=1/m2.determinant(it)	
	return m2.scale({m2.cofactor{m2.transpose(it)}},ood)
end

class("m3",m2)
function m3.new(...) return setmetatable({0,0,0,0,0,0,0,0,0},m3):set(...) end
function m3.determinant(it)
	return	 ( it[ 1 ]*it[ 3+2 ]*it[ 6+3 ] )
			+( it[ 2 ]*it[ 3+3 ]*it[ 6+1 ] )
			+( it[ 3 ]*it[ 3+1 ]*it[ 6+2 ] )
			-( it[ 1 ]*it[ 3+3 ]*it[ 6+2 ] )
			-( it[ 2 ]*it[ 3+1 ]*it[ 6+3 ] )
			-( it[ 3 ]*it[ 3+2 ]*it[ 6+1 ] )
end
function m3.transpose(it)
	return	 it[1],it[3+1],it[6+1], it[2],it[3+2],it[6+2], it[3],it[3+3],it[6+3]
end
function m3.minor_xy(it,x,y)
	local t={}
	for ix=1,3 do
		for iy=1,3 do
			if (ix~=x) and (iy~=y) then
				t[#t+1]=it(ix+((iy-1)*3))
			end
		end
	end
	return m2.determinant(t)
end
function m3.cofactor(it)
	local t={}
	for ix=1,3 do
		for iy=1,3 do
			if (ix~=x) and (iy~=y) then
				t[#t+1]=m3.minor_xy(it,ix,iy)
				if ((ix+iy)%2)==1 then t[#t]=-t[#t] end
			end
		end
	end
	return unpack(t)
end
function m3.adjugate(it)
	return m3.transpose{m3.cofactor(it)}
end
function m3.scale(it,s)
	return it[1]*s,it[2]*s,it[3]*s, it[3+1]*s,it[3+2]*s,it[3+3]*s, it[6+1]*s,it[6+2]*s,it[6+3]*s
end
function m3.inverse(it)
	local ood=1/m3.determinant(it)	
	return m3.scale({m3.cofactor{m3.transpose(it)}},ood)
end

class("m4",m3)
function m4.new(...) return setmetatable({0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},m4):set(...) end
function m4.determinant(it)
return	(it[ 4 ] * it[ 4+3 ] * it[ 8+2 ] * it[ 12+1 ])-(it[ 3 ] * it[ 4+4 ] * it[ 8+2 ] * it[ 12+1 ])-
		(it[ 4 ] * it[ 4+2 ] * it[ 8+3 ] * it[ 12+1 ])+(it[ 2 ] * it[ 4+4 ] * it[ 8+3 ] * it[ 12+1 ])+
		(it[ 3 ] * it[ 4+2 ] * it[ 8+4 ] * it[ 12+1 ])-(it[ 2 ] * it[ 4+3 ] * it[ 8+4 ] * it[ 12+1 ])-
		(it[ 4 ] * it[ 4+3 ] * it[ 8+1 ] * it[ 12+2 ])+(it[ 3 ] * it[ 4+4 ] * it[ 8+1 ] * it[ 12+2 ])+
		(it[ 4 ] * it[ 4+1 ] * it[ 8+3 ] * it[ 12+2 ])-(it[ 1 ] * it[ 4+4 ] * it[ 8+3 ] * it[ 12+2 ])-
		(it[ 3 ] * it[ 4+1 ] * it[ 8+4 ] * it[ 12+2 ])+(it[ 1 ] * it[ 4+3 ] * it[ 8+4 ] * it[ 12+2 ])+
		(it[ 4 ] * it[ 4+2 ] * it[ 8+1 ] * it[ 12+3 ])-(it[ 2 ] * it[ 4+4 ] * it[ 8+1 ] * it[ 12+3 ])-
		(it[ 4 ] * it[ 4+1 ] * it[ 8+2 ] * it[ 12+3 ])+(it[ 1 ] * it[ 4+4 ] * it[ 8+2 ] * it[ 12+3 ])+
		(it[ 2 ] * it[ 4+1 ] * it[ 8+4 ] * it[ 12+3 ])-(it[ 1 ] * it[ 4+2 ] * it[ 8+4 ] * it[ 12+3 ])-
		(it[ 3 ] * it[ 4+2 ] * it[ 8+1 ] * it[ 12+4 ])+(it[ 2 ] * it[ 4+3 ] * it[ 8+1 ] * it[ 12+4 ])+
		(it[ 3 ] * it[ 4+1 ] * it[ 8+2 ] * it[ 12+4 ])-(it[ 1 ] * it[ 4+3 ] * it[ 8+2 ] * it[ 12+4 ])-
		(it[ 2 ] * it[ 4+1 ] * it[ 8+3 ] * it[ 12+4 ])+(it[ 1 ] * it[ 4+2 ] * it[ 8+3 ] * it[ 12+4 ])	
end
function m4.transpose(it)
	return	 it[1],it[4+1],it[8+1],it[12+1], it[2],it[4+2],it[8+2],it[12+2], it[3],it[4+3],it[8+3],it[12+3], it[4],it[4+4],it[8+4],it[12+4]
end
function m4.minor_xy(it,x,y)
	local t={}
	for ix=1,4 do
		for iy=1,4 do
			if (ix~=x) and (iy~=y) then
				t[#t+1]=it[ix+((iy-1)*4)]
			end
		end
	end
	return m3.determinant(t)
end
function m4.cofactor(it)
	local t={}
	for ix=1,4 do
		for iy=1,4 do
			if (ix~=x) and (iy~=y) then
				t[#t+1]=m4.minor_xy(it,ix,iy)
				if ((ix+iy)%2)==1 then t[#t]=-t[#t] end
			end
		end
	end
	return unpack(t)
end
function m4.adjugate(it)
	return m4.transpose{m4.cofactor(it)}
end
function m4.scale(it,s)
	return it[1]*s,it[2]*s,it[3]*s,it[4]*s, it[4+1]*s,it[4+2]*s,it[4+3]*s,it[4+4]*s, it[8+1]*s,it[8+2]*s,it[8+3]*s,it[8+4]*s, it[12+1]*s,it[12+2]*s,it[12+3]*s,it[12+4]*s
end
function m4.inverse(it)
	local ood=1/m4.determinant(it)	
	return m4.scale({m4.cofactor{m4.transpose(it)}},ood)
end



class("v2",array)
function v2.new(...) return setmetatable({0,0},v2):set(...) end

class("v3",v2)
function v3.new(...) return setmetatable({0,0,0},v3):set(...) end

class("v4",v3)
function v4.new(...) return setmetatable({0,0,0,0},v4):set(...) end



class("q4",v4)
function q4.new(...) return setmetatable({0,0,0,0},q4):set(...) end


