-- load up html template stringsdofile("lua/html.lua")local html=require("wetgenes.html")local sys=require("wetgenes.aelua.sys")local dat=require("wetgenes.aelua.data")local wet_string=require("wetgenes.string")local str_split=wet_string.str_splitlocal serialize=wet_string.serialize--------------------------------------------------------------------------------- the serv function, named the same as the file it is in-------------------------------------------------------------------------------function serv_home(srv)local function put(a,b)	srv.put(html.get(a,b))end	loadfile("dash.lua")	srv.set_mimetype("text/html")		put("header",{})		put("mainpage".."<br/>")	put("<a href='/test'>/test</a>".."<br/>")	put("<a href='/chan'>/chan</a>".."<br/>")		put("footer",{time=math.ceil((sys.count()-srv.count_start)*1000)/1000})end