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
	O.offset = 1
	O.index = 1

	O.sections = {} 

	--[[ link to settings using set.getCurrSets()
		sets = getCurrSets()
		O.Header0 = sets.Header0
		O.Header1 = sets.Header1
		O.Header2 = sets.Header2
		O.Point = sets.Point
		O.Question = sets.Questions
	]]

		O.TabLength = 3

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
		else 
			O.offset = O.offset + 1
		end 
	end

	O.depth = 0
	for c in (string.sub(O.txt, start, O.offset - 2)):gmatch(".") do 
		if c == "\t" then 
			O.depth = O.depth + 1
		else 
			break
		end 
	end 

	O.line = O.line + 1
	return string.sub(O.txt, start + O.depth, O.offset - 2) 
end 

O.add = function (newSection)
	O.sections[#O.sections + 1] = newSection
end 

-- TODO needs to check from longest to shortest length 
-- when implementing custom syntax 
O.refreshOutline = function() 
	while O.offset < #O.txt do 
		local line = O.getLine() 
		if string.sub(line,  1,  #O.Header2) == O.Header2 then
			O.add({"Header2", O.depth, O.line, line, O.index})
			O.index = O.index + 1
		elseif string.sub(line,  1,  #O.Header1) == O.Header1 then
			O.add({"Header1", O.depth, O.line, line, O.index})
			O.index = O.index + 1
		elseif string.sub(line,  1,  #O.Header0) == O.Header0 then
			O.add({"Header0", O.depth, O.line, line, O.index})
			O.index = O.index + 1
		else if string.sub(line,   1,  #O.Point) == O.Point then
			O.add({"Point", O.depth, O.line, line, O.index})
			O.index = O.index + 1
		elseif string.sub(line,	 1,  #O.Question) == O.Question then
			O.add({"Question", O.depth, O.line, line, O.index})
			O.index = O.index + 1
		end end 
	end 
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
		position = "50%", 
		focusable = true, 
		enter = true, 
		size = 50, 
		border = {
			style = "double",
		},
		buf_options = { 
			modifiable = true, 
			readonly = false
		}, 
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:FloarBorder",
		}
	})
	 
	local sectionLines = {} 
	for i = 1, #O.sections do 
		if (#O.sections[i][4] > 50) then
			sectionLines[#sectionLines + 1] = Menu.item(string.rep("\t", O.sections[i][2]) .. string.sub(O.sections[i][4], 1, 45) .. "...", { id =  O.sections[i][5] })
		else 
			sectionLines[#sectionLines + 1] = Menu.item(string.rep("\t", O.sections[i][2]) .. O.sections[i][4], { id =  O.sections[i][5] })
		end 
	end 

	local menu = Menu(pop_opts, { 
		max_width = 40, 
		max_width = 20, 
		lines = sectionLines,  
		keymap = { 
			focus_next = {"j"}, 
			focus_prev = {"k"}, 
			close = {"<Esc>"}, 
			submit = {"<CR>"} 
		}, 

		on_submit = function (item) 
			print (vim.inspect(item)) 
		end 
	})


	menu:update_layout({
		relative = "win",
		position = { 
			row = "0%", 
			col = "100%", 
		},  
		focusable = true, 
		enter = true, 
		size = {
			width = 100, 
			height = "75%", 
		}, 
		border = {
			style = "single",
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

	local pop_opts = Popup({
		relative = "win",
		position = "50%", 
		focusable = true, 
		enter = true, 
		size = 50, 
		border = {
			style = "single",
		},
		buf_options = { 
			modifiable = true, 
			readonly = false
		}, 
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:FloarBorder",
		}
	})
	 
	local sectionLines = {} 
	for i = 1, #O.sections do 
		if (#O.sections[i][4] > 50) then
			sectionLines[#sectionLines + 1] = Menu.item(string.rep("\t", O.sections[i][2]) .. string.sub(O.sections[i][4], 1, 45) .. "...", { id =  O.sections[i][5] })
		else 
			sectionLines[#sectionLines + 1] = Menu.item(string.rep("\t", O.sections[i][2]) .. O.sections[i][4], { id =  O.sections[i][5] })
		end 
	end 

	local menu = Menu(pop_opts, { 
		max_width = 40, 
		max_width = 20, 
		lines = sectionLines,  
		keymap = { 
			focus_next = {"j"}, 
			focus_prev = {"k"}, 
			close = {"<Esc>"}, 
			submit = {"<CR>"} 
		}, 
	})


	menu:update_layout({
		relative = "win",
		position = { 
			row = "0%", 
			col = "100%", 
		},  
		focusable = true, 
		enter = true, 
		size = {
			width = 100, 
			height = "75%", 
		}, 
		border = {
			style = "single",
		}
	})
	menu:mount() 
end 

O.HeaderSearch = function () 
end 

O.init() 
O.minimalNav() 
