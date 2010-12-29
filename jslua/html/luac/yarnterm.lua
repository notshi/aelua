package.path=package.path..";./?/init.lua"

local yarn=require("yarn")

local function keycode(code)

--print(code)

	if code==65  then return "up" end
	if code==66  then return "down" end
	if code==68  then return "left" end
	if code==67  then return "right" end
	if code==32  then return "space" end
	if code==127 then return "backspace" end
	if code==27  then return "esc" end
	if code==10  then return "enter" end

	return ""
end

local aesc=string.char(27) .. '['

yarn.setup()
yarn.update()
print( aesc.."2J"..aesc.."0;0H"..yarn.draw(2) )

local exit=false
while not exit do

	local key_str=io.stdin:read(1)
	
	local key=keycode( key_str:byte() )
	
	if key_str=="q" then exit=true end

	yarn.keypress(key_str,key,"down")
	yarn.keypress(key_str,key,"up")
	yarn.update()
	print( aesc.."0;0H"..yarn.draw(2) )

end


