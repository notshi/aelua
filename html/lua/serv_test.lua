-- load up html template stringsdofile("lua/html.lua")local html=require("wetgenes.html")local sys=require("wetgenes.aelua.sys")local dat=require("wetgenes.aelua.data")local user=require("wetgenes.aelua.user")local log=require("wetgenes.aelua.log").log -- grab the func from the packagelocal wet_string=require("wetgenes.string")local str_split=wet_string.str_splitlocal serialize=wet_string.serialize--------------------------------------------------------------------------------- the serv function, named the same as the file it is in-------------------------------------------------------------------------------function serv_test(srv)local function put(a,b)	srv.put(html.get(a,b))end	log("REQ: "..srv.url)		srv.set_cookie({name="poop",value="now",live=60,domain=nil,path="/"})		srv.set_mimetype("text/html")	put("header",{})		put("<a href='{log}'>login</a><br/>",{log=user.login_url("/test/")})	put("<a href='{log}'>logout</a><br/>",{log=user.logout_url("/test/")})		srv.put( tostring(user).."<br/><br/>")		srv.put( tostring(srv).."<br/><br/>")		srv.put( tostring(package.path) .."<br/>" )		srv.put( tostring(dat.str) .."<br/>" )	srv.put( tostring(wetgenes.aelua) .."<br/>" )			local ent={}		ent.props={		email="poo poo head",		num=23,		text="nobody here",		}		ent.key={kind="test",id=1}	ent.props.num=0;	local key=dat.put(ent)		ent.key={kind="test",id=1,parent=key}	ent.props.num=5;	dat.put(ent)		ent.key={kind="test",id="plop1"}	ent.props.num=19;	dat.put(ent)	ent.key={kind="test",id="plop2"}	ent.props.num=23;	dat.put(ent)		ent.key={kind="test",id="plop3"}	ent.props.num=42;	dat.put(ent)		local t=dat.query({		kind="test",		limit=10,		offset=0,			{"filter","num",">=",0},			{"filter","num","<=",23},			{"sort","num",">"},		})			srv.put( tostring(t.code).."<br/>" )	for i,v in  ipairs(t) do		srv.put( tostring(v).."<br/>" )	end		local t=dat.query({		parent=key,		kind="test",		limit=10,		offset=0,			{"filter","num",">=",0},			{"filter","num","<=",23},			{"sort","num",">"},		})			srv.put( tostring(t.code).."<br/>" )	for i,v in  ipairs(t) do		srv.put( tostring(v).."<br/>" )	end			srv.put( "Time elapsed : " .. math.ceil((sys.count()-srv.count_start)*1000) .."ms<br/>" )	put("footer",{})	end