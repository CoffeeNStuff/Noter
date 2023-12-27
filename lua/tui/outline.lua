-- search through outline of notes 


-- open panel with contents 'loading ... ' 
-- get file contents
-- form into outline 
-- display to panel 
-- ability to jump to header/point 
-- points and headers are colapsable in panel 

local O = {} 

O.init = function () 
	O.txt = io.open(vim.fn.expand("%:p", "r")):read("a") 
	O.depth = 0
	O.line = 1
	O.offset = 1

	O.sections = {} 

	--[[ link to settings using set.getCurrSets()
		sets = getCurrSets()
		O.Header0 = sets.Header0
		O.Header1 = sets.Header1
		O.Header2 = sets.Header2
		O.Point = sets.Point
		O.Question = sets.Questions
	]]

		O.Header0 = "|||"
		O.Header1 = "||"
		O.Header2 = "|"
		O.Point = "-"
		O.Question = "??"

		O.refreshOutline()
end 

O.getLine = function () 
	local start = O.offset 

	while O.offset < #O.txt do 
		O.offset = O.offset + 1 
		if string.sub(O.txt, O.offset, O.offset) == "\n" then 
			break 
		end
	end

	-- goes up to a depth of 5
	if string.sub(O.txt, start + 1, start + 1) ~= "\t" then 
		O.depth = 0
	elseif string.sub(O.txt, start + 1, start + 6) == "\t\t\t\t\t" then 
		O.depth = 1
	elseif string.sub(O.txt, start + 1, start + 5) == "\t\t\t\t" then 
		O.depth = 2
	elseif string.sub(O.txt, start + 1, start + 4) == "\t\t\t" then 
		O.depth = 3
	elseif string.sub(O.txt, start + 1, start + 3) == "\t\t" then 
		O.depth = 4
	elseif string.sub(O.txt, start + 1, start + 2) == "\t" then 
		O.depth = 5
	end 

	return string.sub(O.txt, start + 1, O.offset) 
end 

O.currLine = function () 
	while O.offset > 0 do 
		O.offset = O.offset - 1 
		if string.sub(O.txt, O.offset, O.offset) == "\n" then 
			break 
		end
	end
	return O.getLine()
end 
 
O.add = function (newSection)
	O.sections[#O.sections + 1] = newSection
end 

-- TODO needs to check from longest to shortest length 
-- when implementing custom syntax 
O.refreshOutline = function() 
	while O.offset < #O.txt do 
		local line = O.getLine()

		if string.sub(line, 1,  #O.Header2) == O.Header2 then
			O.add({"Header2", O.depth, O.line, O.currLine()})
		elseif string.sub(line, 1,  #O.Header1) == O.Header1 then
			O.add({"Header1", O.depth, O.line, O.currLine()})
		elseif string.sub(line, 1,  #O.Header0) == O.Header0 then
			O.add({"Header0", O.depth, O.line, O.currLine()})
		else if string.sub(line, 1,  #O.Point) == O.Point then
			O.add({"Point", O.depth, O.line, O.currLine()})
		elseif string.sub(line, 1,  #O.Question) == O.Question then
			O.add({"Question", O.depth, O.line, O.currLine()})
		end 
		O.line  = O.line + 1
	end 

	for i = 1, #O.sections do 
		vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win, {O.sections[i][3], 1})
	end 
end
end 


--[[┌──────────────────────────────────────────────────┐
	 │                                                  │
	 │    ┌───────────────────┐┌───────────────────┐    │
	 │    │                   ││                   │    │
	 │    │                   ││                   │    │
	 │    │                   ││                   │    │
	 │    │      Results      ││                   │    │
	 │    │                   ││      Preview      │    │
	 │    │                   ││                   │    │
	 │    │                   ││                   │    │
	 │    └───────────────────┘│                   │    │
	 │    ┌───────────────────┐│                   │    │
	 │    │      Prompt       ││                   │    │
	 │    └───────────────────┘└───────────────────┘    │
	 │                                                  │
	 └──────────────────────────────────────────────────┘]] 
O.HeaderSearch = function () 
end 

--[[
	 ┌───Minimal Navigate───┐
	 │> Header0             │
	 │ > Header1            │
	 │  > Header 2          │
	 │                      │
	 │                      │
	 │                      │
	 │                      │
	 │                      │
	 │                      │
	 │                      │
	 │                      │
	 │                      │
	 │                      │
	 │                      │
	 │                      │
	 │--- File.txt ---      │
	 └──────────────────────┘
||| hello there
]]
-- shows current depth
-- for example only show Header0's or subpoints
-- able to deepen or lessen using '-' and '+' 
O.minimalNav = function () 
	O.refreshOutline()
end 

-- shows all headers 0 - 2
O.medianNav = function () 
	O.refreshOutline()
end 

-- shows entire outline with up 
-- to 3 subpoints
O.maximalNav = function () 
	O.refreshOutline()
end 


return O 
