-- load up html template stringsdofile("lua/html.lua")local html=require("wetgenes.html")local dat=require("wetgenes.aelua.data")local log=require("wetgenes.aelua.log").log -- grab the func from the packagelocal wet_string=require("wetgenes.string")local str_split=wet_string.str_splitlocal serialize=wet_string.serialize--------------------------------------------------------------------------------- the serv function, named the same as the file it is in-------------------------------------------------------------------------------function serv_test(srv)local function put(a,b)	srv.print(html.get(a,b))end	log("REQ: "..srv.url)			srv.mimetype("text/html")	put("header",{})			srv.print("plop".."<br/>")		srv.print( tostring(package.path) .."<br/>" )		srv.print( tostring(dat.str) .."<br/>" )	srv.print( tostring(wetgenes.aelua) .."<br/>" )			local ent={}		ent.props={		email="poo poo head",		num=23,		text="nobody here",		}		ent.key={kind="test",id=1}	ent.props.num=0;	dat.put(ent)		ent.key={kind="test",id="plop1"}	ent.props.num=19;	dat.put(ent)	ent.key={kind="test",id="plop2"}	ent.props.num=23;	dat.put(ent)		ent.key={kind="test",id="plop3"}	ent.props.num=42;	dat.put(ent)		local t=dat.query({		kind="test",		limit=10,		offset=0,			{"filter","num",">=",0},			{"filter","num","<=",23},			{"sort","num",">"},		})			srv.print( tostring(t.code).."<br/>" )		for i,v in  ipairs(t) do		srv.print( tostring(v).."<br/>" )	end			srv.print( "Time elapsed : " .. math.ceil((srv.nanotime()-srv.stamp_time)*1000) .."ms<br/>" )	put("footer",{})	end