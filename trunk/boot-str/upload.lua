#!/usr/bin/lua

function buildxml(name)
local s=[[<appengine-web-app xmlns="http://appengine.google.com/ns/1.0">
  <!-- Replace this with your application id from http://appengine.google.com -->
  <application>]]..name..[[</application>
  <version>1</version>
</appengine-web-app>]]
	local fp=assert(io.open("html/WEB-INF/appengine-web.xml","w"))
	fp:write(s)
	fp:close();
end


-- allways end on boot-str
for i,v in ipairs{
"cake-or-games",
"boot-str"} do

	buildxml(v)
	
	os.execute("make upload")

end


buildxml("boot-str")
