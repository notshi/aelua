
-- this needs an ipv4.csv file from http://software77.net/

local fp = io.open("ipv4.csv","r")

local tab={}

for line in fp:lines() do

	local s=line:sub(1,1)
	if s=="#" then -- ignore comments
	else
		local ib,ie,ia,it,co = line:match('"(%d+)","(%d+)","([^"]+)","([^"]+)","([^"]+)"')

		if ib and ie and co then -- ignore all other junk
		
			if #co==2 then
				ib=tonumber(ib)
				ie=tonumber(ie)
				co=tostring(co):upper()
				if ib<0 then ib=0 end
				if ie>4294967295 then ie=4294967295 end
				tab[#tab+1]={ib,ie,co}
			end
		end
	end
end
fp:close()

table.sort(tab,function(a,b) return a[1]<b[1] end)

local ins={}
for i,v in ipairs(tab) do
	local w=tab[i+1]
	if w then
		if v[2]>=w[1] then
print("overlap ",v[1],v[2],v[3])
print("overlap ",w[1],w[2],w[3])
			v[2]=w[1]-1
		end
		if v[2]~=w[1]-1 then
			ins[#ins+1]={v[2]+1,w[1]-1,"ZZ"}
--print("unknown ",v[2]+1,w[1]-1,"--")
		end
 	end
end

print("adding "..#tab.." ranges")

-- stick the new bits in and sort again
for i,v in ipairs(ins) do
	tab[#tab+1]=v
end
table.sort(tab,function(a,b) return a[1]<b[1] end)

print("adding "..#ins.." missing ranges")

-- now merge all codes that are next to each other

local nt={}
local i=1
while true do
	local v=tab[i]
	local w=tab[i+1]

	if v and w and ( v[3]==w[3] ) then -- merge
		local it={v[1],v[2],v[3]}
		while w and (v[3]==w[3]) do
--print("merge ",v[1],v[2],v[3])
			i=i+1
			it[2]=w[1]-1
			w=tab[i+1]
		end
		nt[#nt+1]=it -- just copy
	else
		nt[#nt+1]=v -- just copy
	end
	
	if (not v) or (not w) then
		break
	end
	i=i+1
end
print("found "..#tab.." ranges")
tab=nt
print("merged to "..#tab.." ranges")

local fp = io.open("../mods/admin/lua/ipv4_tab.lua","w")

fp:write("module(...)\n")
fp:write("data={\n")

for i,v in ipairs(tab) do

	local len=1+v[2]-v[1]
	
	if len>0 then -- ignore bad ranges
		fp:write(string.format("%u,%q,\n",v[1],v[3]))
	end

end

fp:write("}\n")
fp:close()
