
local wet_html=require("wetgenes.html")
local json=require("json")

local dat=require("wetgenes.aelua.data")
local cache=require("wetgenes.aelua.cache")

local users=require("wetgenes.aelua.users")

local img=require("wetgenes.aelua.img")

local log=require("wetgenes.aelua.log").log -- grab the func from the package

local wet_string=require("wetgenes.string")
local str_split=wet_string.str_split
local serialize=wet_string.serialize


-- require all the module sub parts
local html   =require("hoe.html")
local players=require("hoe.players")


local math=math
local string=string
local table=table

local ipairs=ipairs
local tostring=tostring
local tonumber=tonumber
local type=type

-- manage rounds
-- not only may there be many rounds active at once
-- information may still be requested about rounds that have finished

module("hoe.feats")

--------------------------------------------------------------------------------
--
-- build some top players for the given roundid
-- find the top 3 in a number of catagorys
-- only return wetgenes emails for privacy issues?
--
--------------------------------------------------------------------------------
function get_top_players(H,round_id)

	-- a unique keyname for this query
	local cachekey="feats=get_top_players&round="..round_id

	local r=cache.get(H.srv,cachekey) -- do we already know the answer
	if r then return json.decode(r) end

	local ret={}
	
	local list=players.list(H,{sort="score",limit=100,order="DESC",round_id=round_id})
	
	local t={}
	local topscore=1
	for i=1,#list do local v=list[i]
		local crowns=""
		local c=0
		if i==1 then
			topscore=v.cache.score
			if topscore<1 then topscore=1 end -- sane
			c=10
		else
			c=math.floor(10*v.cache.score/topscore)
		end

		if c>10 then c=10 end -- sane
		if c<0  then c=0  end -- sane
		t[#t+1]={ id=v.cache.email , crown=c , score=v.cache.score }
	end
	
	ret.info=t
	
	cache.put(H.srv,cachekey,json.encode(ret),10*60) -- save this new result for 10 mins
	return ret
end


