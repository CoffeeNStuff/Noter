--[[
|	Control Panel
|	file.txt 
|=================
| Setting ~ Value  
| Setting ~ Value  
| Setting ~ Value  
| Setting ~ Value  
| Setting ~ Value  
| Setting ~ Value  
| Setting ~ Value  

| Keystroke ~ to exit
]] 

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
	"AutoIndent":				true,
	"AutoColapse": 			false,
	"TextWidth":  				70 

	Syntax: { 
		first { 
			"Point":  			"-"
			"Header0":  		"|" 
			"Header1":  		"||"  
			"Header2":  		"|||"  

			"Question":  		"??"  
			"Comment":  		"*"  
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

function modSet () 
	local sets = getCurrSet () 
	print(sets.Syntax)
end 

modSet(); 
