require("lfs") 
local json = require("json") 

function initConfig () 
	local home = os.getenv("HOME") 
	lfs.mkdir(home .. "/.config/Noter")
	lfs.touch(home .. "/.config/Noter/config.json") 
	local file =  io.open(home .. "/.config/Noter/config.json", "w")
	
	file:write([[{ 
	"ConfigFileLocation": 	"~/.config/Noter/config.json",
	"NoteFileLocation": 		"~/.config/Noter/config.json", 
	"Syntax":					"Noter",
	"ContinualFormatting":	false,
	"AutoIndent":				true,
	"AutoColapse": 			false,
	"TextWidth":  				70, 

	Syntax: { 
		default: { 
			"Point":  			"-", 
			"Header0":  		"|", 
			"Header1":  		"||",   
			"Header2":  		"|||", 

			"Question":  		"??",
			"Comment":  		";;",

			"Combos": [
				"TODO",  
				"TOREF" 
			] 
		} 
	} 
} 
	]]) 
	file:close()
end 


function getCurrSet () 
	local home = os.getenv("HOME") 
	local file =  io.open(home .. "/.config/Noter/config.json", "r")

	if file == nil then 
		initConfig() 	
		file =  io.open(home .. "/.config/Noter/config.json", "r")
	end 

	return json.decode(file:read("a"))
end 

--[[
 ┌──Control Panel───────┐
 │Setting - Value       │
 │Setting - Value       │
 │Setting - Value       │
 │Setting - Value       │
 │Setting - Value       │
 │Setting - Value       │
 │Setting - Value       │
 │Setting - Value       │
 │Setting - Value       │
 │                      │
 │                      │
 │                      │
 │                      │
 │                      │
 │--- File.txt ---      │
 └──────────────────────┘]]
function modSet () 
	local sets = getCurrSet () 
end 
