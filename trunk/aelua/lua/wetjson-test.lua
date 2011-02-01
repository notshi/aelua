
local wetjson=require("wetjson")
local json=require("json")

print("starting json tests")

local strs={

[[
{
    "glossary": {
        "title": "example \"\" glossary",
		"GlossDiv": {
            "title": 24 ,
			"GlossList": {
                "GlossEntry": {
                    "ID": "SGML",
					"SortAs": "SGML",
					"GlossTerm": "Standard Generalized Markup Language",
					"Acronym": "SGML",
					"Abbrev": "ISO 8879:1986",
					"GlossDef": {
                        "para": "A \\ meta-markup language, used to create markup languages such as DocBook.",
						"GlossSeeAlso": ["GML", "XML"]
                    },
					"GlossSee": "markup"
                }
            }
        }
    }
}
]],

[[
{"widget": {
    "debug": "on",
    "window": {
        "title": "Sample Konfabulator Widget",
        "name": "main_window",
        "width": 500,
        "height": 500
    },
    "image": { 
        "src": "Images/Sun.png",
        "name": "sun1",
        "hOffset": 250,
        "vOffset": 250,
        "alignment": "center"
    },
    "text": {
        "data": "Click Here",
        "size": 36545634567474747474747474,
        "style": "bold",
        "name": "text1",
        "hOffset": 250,
        "vOffset": 100,
        "alignment": "center",
        "onMouseUp": "sun1.opacity = (sun1.opacity / 100) * 90;"
    }
}}
]],


}

for i,v in ipairs(strs) do

--if i~=1 then os.exit(0) end

print("INPUT")
	print(v)
	
print("OUTPUT")
	local t=wetjson.decode(v)
	local s=wetjson.encode(t)
	print(s)
	
print("MIRROR")
	local s2=wetjson.encode(wetjson.decode(s))
	print(s2)

print("DONE")

end

print("JSON")
print(os.time())
for i=1,1000 do
	for i,v in ipairs(strs) do

		local t=json.decode(v)
--		local s=json.encode(t)

	end
end
print(os.time())

print("WETJSON")
print(os.time())
for i=1,1000 do
	for i,v in ipairs(strs) do

		local t=wetjson.decode(v)
--		local s=wetjson.encode(t)

	end
end
print(os.time())

