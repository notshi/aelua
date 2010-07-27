



local json=require("json")


local pairs=pairs




local core=require("wetgenes.aelua.data.core")

module("wetgenes.aelua.data")


local kind_props={}	-- default global props mapped to kinds



function keyinfo(keystr)

	return core.keyinfo(keystr)

end

function keystr(kind,id,parent)

	return core.keystr(kind,id,parent)

end



function del(ent)

	return core.del(nil,ent)

end

function put(ent)

	return core.put(nil,ent)

end

function get(ent)

	return core.get(nil,ent)

end

function query(q)

	return core.query(nil,q)

end

-----------------------------------------------------------------------------
--
-- Begin a transaction, use the functions inside the returned table
-- to perform actions within this transaction
--
-- the basic code flow is that you should begin one transaction per entity(parent)
-- and then rollback all when one fails. the first del/put/get locks the entity
-- we are dealing with in this transaction
--
-- after the t.fail flag gets set on a put/del then everything apart from rollback just returns nil
-- and commit is turned into an auto rollback
--
-- so this is OK transaction code, just remember that puts may not auto generate a key
-- and there may be other reasons for fails
--
-- for _=1,10 do -- try a few times
--     t=begin()
--     if t.get(e) then e.props.data=e.props.data.."new data" end
--     t.put(e)
--     if t.commit() then break end -- success
-- end
--
-----------------------------------------------------------------------------
function begin()

	local t={}
	t.core=core.begin()
	
	t.fail=false -- this will be set to true when a transaction action fails and you should rollback and retry
	t.done=false -- set to true on commit or rollback to disable all methods
	
 -- these methods are the same as the global ones but operate on this transaction
 	t.del=function(ent)	if t.fail or t.done then return nil end return core.del(t,ent) end
	t.put=function(ent)	if t.fail or t.done then return nil end return core.put(t,ent) end
	t.get=function(ent)	if t.fail or t.done then return nil end return core.get(t,ent) end
	t.query=function(q)	if t.fail or t.done then return nil end return core.query(t,q) end
	
	t.rollback=function() -- returns false to imply that nothing was commited
		if t.done then return false end -- safe to rollback repeatedly
		t.done=true
		t.fail=not core.rollback(t.core) -- we always set fail and return false
		return not t.fail
	end	
	
	t.commit=function() -- returns true if commited, false if not
		if t.done then return false end -- safe to rollback repeatedly
		if t.fail then -- rollback rather than commit
			return t.rollback()
		end
		t.done=true
		t.fail=not core.commit(t.core)
		return not t.fail
	end

	return t
end


-----------------------------------------------------------------------------
--
-- build cache which is a mixture of decoded json vars (this may contain sub tables)
-- overiden by database props which do not contain tables but are midly searchable
-- props.json should contain this json data string on input
-- cache will be a filled in table to be used instead of props
--
-- Not sure if this is more compact than just creating many real key/value pairs
-- but it feels like a better way to organize. :)
--
-- At least it is a bit more implicit about what can and cannot be searched for.
--
-- the idea is everything we need is copied into the cache, you can edit it there
-- and then build_props will do the reverse in preperation for a put
--
-----------------------------------------------------------------------------
function build_cache(e)

	if e.props.json then -- expand the json data
	
		e.cache=json.decode(e.props.json)
		
	else
	
		e.cache={}
	
	end

	for i,v in pairs(e.props) do -- override cache by props
		e.cache[i]=v
	end
	
	e.cache.json=nil -- not the json prop
	
	if e.key then -- copy the key data
		e.cache.parent=e.key.parent
		e.cache.kind=e.key.kind
		e.cache.id=e.key.id
	end
	
	return e
end
-----------------------------------------------------------------------------
--
-- a simplistic reverse of build cache
-- any props of the same name will get updated from this cache
-- rather than encoded into props.json
--
-----------------------------------------------------------------------------
function build_props(e)

	local t={}
	local ignore={kind=true,id=true,parent=true,json=true,} -- special names to ignore
	
	for i,v in pairs(e.cache) do
		if ignore[i] then -- ignore these special names
		elseif e.props[i] then
			e.props[i]=v -- if it exists as a prop then the prop is updated
		else
			t[i]=v -- else it just goes into the json prop
		end
	end
	e.props.json=json.encode(t)
	
	return e
end
