-- search through outline of notes
-- open panel with contents 'loading ... ' 
-- get file contents
-- form into outline 
-- display to panel 
-- ability to jump to header/point 
-- points and headers are colapsable in panel 

local Popup = require("nui.popup") 
local Menu = require("nui.menu") 
local event = require ("nui.utils.autocmd").event

local O = {} 

O.init = function () 
	O.txt = io.open(vim.fn.expand("%:p"), "r"):read("a") 
	O.depth = 0
	O.line = 0
	O.offset = 0

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
end 

O.getLine = function () 
	local start = O.offset 

	while O.offset < #O.txt do 
		if string.sub(O.txt, O.offset, O.offset) == "\n" then 
			O.offset = O.offset + 1
			break 
		end
		O.offset = O.offset + 1
	end

	-- goes up to a depth of 5
	if string.sub(O.txt, start + 1, start + 1) ~= "\t" then 
		O.depth = 0
	elseif string.sub(O.txt, start + 1, start + 5) == "\t\t\t\t\t" then 
		O.depth = 5
	elseif string.sub(O.txt, start + 1, start + 4) == "\t\t\t\t" then 
		O.depth = 4
	elseif string.sub(O.txt, start + 1, start + 3) == "\t\t\t" then 
		O.depth = 3
	elseif string.sub(O.txt, start + 1, start + 2) == "\t\t" then 
		O.depth = 2
	elseif string.sub(O.txt, start + 1, start + 1) == "\t" then 
		O.depth = 1
	end 

	O.line  = O.line + 1
	return string.sub(O.txt, start + 1, O.offset - 1) 
end 

O.add = function (newSection)
	O.sections[#O.sections + 1] = newSection
end 

-- TODO needs to check from longest to shortest length 
-- when implementing custom syntax 
O.refreshOutline = function() 
	while O.offset < #O.txt do 
		local line = string.sub(O.getLine(), O.depth + 1) 
		if string.sub(line, 1,  #O.Header2) == O.Header2 then
			O.add({"Header2", O.depth, O.line, line})
		elseif string.sub(line, 1,  #O.Header1) == O.Header1 then
			O.add({"Header1", O.depth, O.line, line})
		elseif string.sub(line, 1,  #O.Header0) == O.Header0 then
			O.add({"Header0", O.depth, O.line, line})
		else if string.sub(line, 1,  #O.Point) == O.Point then
			O.add({"Point", O.depth, O.line, line})
		elseif string.sub(line, 1,  #O.Question) == O.Question then
			O.add({"Question", O.depth, O.line, line})
		end end 
	end 
end


O.HeaderSearch = function () 
end 


-- ┌───Minimal Navigate───┐
-- │> Header0             │
-- │ > Header1            │
-- │  > Header 2          │
-- │                      │
-- │                      │
-- │                      │
-- │                      │
-- │                      │
-- │                      │
-- │                      │
-- │                      │
-- │                      │
-- │                      │
-- │                      │
-- │                      │
-- │--- File.txt ---      │
-- └──────────────────────┘

-- shows only current depth
-- able to deepen or lessen using '-' and '+' 
O.minimalNav = function () 
	O.refreshOutline()

	local pop_opts = Popup({
	  relative = "win",
	  position = {
		 row = 1,
		 col = 0,
	  },
	  size = {
		  width = 20, 
		  height = 40
		}, 
	  border = {
		 style = "single",
	  },
	  win_options = {
		 winhighlight = "Normal:Normal",
	  }
	})
	 
	local menu = Menu(pop_opts, { 
		max_width = 20, 
		lines = { 
			Menu.item("privet!"), 
		}, 
		keymap = { 
			close = {"<Esc>"}, 
			focus_next = {"j", "<Down>"}, 
			focus_prev = {"k", "<Down>"}, 
			submit = {"<CR>"} 
		}
	})

	menu:mount() 
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

O.init() 
O.minimalNav() 
