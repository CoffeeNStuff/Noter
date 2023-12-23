--[[ 
Example JSON file 
{ 
	"ConfigFileLocation" =  	
	"NoteFileLocation" =  	
	"Syntax" =  	
	"AutoIndent" =  	
	"AutoColapse" =  	
	"TextWidth" =  	
} 
]]   

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

setStruct = {
	['ConfigFileLocation'] = "~/.config/Noter/config.json", 
	['NoteFileLocation'] = "~/.config/Noter/config.json", 
	['Syntax'] = "Noter", 
	['AutoIndent'] = true, 
	['AutoColapse'] = false, 
	['TextWidth'] = 70, 
	['AutoWidth'] = false,
}
 
function getCurrSet () 
end 

function set () 
end 

