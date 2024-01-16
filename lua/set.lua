local set =  { 
	initConfig = function () 
		local home = os.getenv("HOME") 
		local file =  io.open(home .. "/.config/Noter/config.json", "w")

		if file == nil then 
			os.execute( "mkdir ".. home .. "/.config/Noter")
			os.execute( "touch " .. home .. "/.config/Noter/config.json") 
			file =  io.open(home .. "/.config/Noter/config.json", "w")
		else 
			return 
		end 

		
		file:write([[{ 
		"ConfigFileLocation": 	"~/.config/Noter/config.json",
		"Syntax":					"Noter",
		
		Syntax: { 
			default: [ 
				{"name": "Header0", "c": "|", "pri": 0 }, 
				{"name": "Header1", "c": "||", "pri": 1 }, 
				{"name": "Header2", "c": "|||", "pri": 2 }, 
				{"name": "Point",   "c": "-", "pri": 3 }, 
				{"name": "Question", "c": "??", "pri": 3 },  
				{"name": "To Read on", "c": ";;", "pri": 3 }, 
			],  

			Responsio: [ 
				{"name": "Question", "c": "|", "pri": 1 }, 
				{"name": "Thesis", "c": "~", "pri": 2 } 
				{"name": "Objection", "c": "-", "pri": 3 } 
				{"name": "Response", "c": "+", "pri": 3}
			] 
		} 
	} 
		]]) 
		file:close()
	end,

	getSyntax = function () -- TODO custom syntax 
		local default = { 
			{name = "Header0", c = "|", pri = 0 }, 
			{name = "Header1", c = "||", pri = 1 }, 
			{name = "Header2", c = "|||", pri = 2 }, 
			{name = "Point",   c = "-", pri = 3 }, 
			{name = "Question", c =  "??", pri = 3 },  
			{name = "To Read on", c = ";;", pri =  3 }, 
		} 

		return table.sort(default, function (a, b) 
			return a.pri < b.pri
		end) 
	end 
} 

return set
