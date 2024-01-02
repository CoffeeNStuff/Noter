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

local ui = vim.api

local O = {
	initialized = false
} 

O.init = function () 
	O.NotesWindow = vim.api.nvim_get_current_win()
	O.buf = ui.nvim_create_buf(false, false) 
	O.win = nil 
	O.txt = {}
	O.sections = {} 
	O.currSections = {} 
	O.currLines = {} 

	O.depth = 0
	O.line = 0
	O.offset = 1
	O.index = 1

	O.open = false 
	O.currDepth = 0 

	
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

		ui.nvim_buf_set_keymap(O.buf, 'n', 'q', ':lua noterClose()<CR>', { silent = true }) 
		ui.nvim_buf_set_keymap(O.buf, 'n', '<esc>', ':lua noterClose()<CR>', { silent = true }) 
		ui.nvim_buf_set_keymap(O.buf, 'n', '<CR>', ':lua noterSubmit()<CR>', { silent = true }) 

		ui.nvim_buf_set_keymap(O.buf, 'n', '<Tab>', ':lua noterToggle()<CR>', { silent = true }) 
		ui.nvim_buf_set_keymap(O.buf, 'n', '+', ':lua noterProgress()<CR>', { silent = true }) 
		ui.nvim_buf_set_keymap(O.buf, 'n', '-', ':lua noterRegress()<CR>', { silent = true }) 
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
	O.txt = io.open(vim.fn.expand("%:p"), "r"):read("a") 
	O.sections = {} 
	while O.offset < #O.txt do 
		local line = O.getLine() 
		if string.sub(line,  1,  #O.Header2) == O.Header2 then
			O.add({"Header2", O.depth, O.line, line, #O.sections + 1 }) 
		elseif string.sub(line,  1,  #O.Header1) == O.Header1 then
			O.add({"Header1", O.depth, O.line, line, #O.sections + 1 }) 
		elseif string.sub(line,  1,  #O.Header0) == O.Header0 then
			O.add({"Header0", O.depth, O.line, line, #O.sections + 1 })
		else if string.sub(line,   1,  #O.Point) == O.Point then
			O.add({"Point", O.depth, O.line, line, #O.sections + 1})
		elseif string.sub(line,	 1,  #O.Question) == O.Question then
			O.add({"Question", O.depth, O.line, line, #O.sections + 1})
		end end 
	end 

	O.currSections = {} 
	O.currLines = {} 
	for i = 1, #O.sections do 
		if O.sections[i][2] >= O.currDepth then
			O.currSections[#O.currSections + 1] = O.sections[i] 
			O.currLines[#O.currLines + 1] = string.rep('\t', O.sections[i][2] - O.currDepth) .. O.sections[i][4]
		end 
	end
end 

--[[ shows only current depth
-- able to deepen or lessen using '-' and '+' 
minimalNav = function () 
	if  O.menu ~= nil then 
		O.menu:unmount()	
		O.menu = nil
		return
	end

	O.init() 
	O.refreshOutline()
	
	local sectionLines = {} 
	for i = 1, #O.sections do 
		if (#O.sections[i][4] > 50) then
			sectionLines[#sectionLines + 1] = Menu.item(string.rep("\t", O.sections[i][2]) .. string.sub(O.sections[i][4], 1, 45) .. "...", { id =  O.sections[i][5] })
		else 
			sectionLines[#sectionLines + 1] = Menu.item(string.rep("\t", O.sections[i][2]) .. O.sections[i][4], { id =  O.sections[i][5] })
		end 
	end 

	local menu = Menu(Popup({}), { 
		focusable = true, 
		enter = true, 

		relative = "win",
		position = "50%", 
		size = 50, 
		max_width = 40, 
		max_width = 20, 
		border = {
			style = "double",
		},

		lines = sectionLines,  
		buf_options = { 
			modifiable = true, 
			readonly = false
		}, 
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:FloarBorder",
		}, 

		keymap = { 
			focus_next = {"j"}, 
			focus_prev = {"k"}, 
			close = {"<Esc>"}, 
			submit = {"<CR>"} 
		}, 
		
		on_submit = function (item) 
			if (item ~= nil) then 
				vim.api.nvim_win_set_cursor(O.NotesWindow, {O.sections[item.id][3], O.sections[item.id][2]}) 
			end
			O.menu = nil
		end,  

		on_close = function () 
			O.menu = nil
		end, 
	})

	local regress = menu:map("n", "-", function()
		if O.currDepth == 0 then 
			print "no shallower" 
		else 
			O.currDepth = O.currDepth - 1

			local newLines = {} 
			for i = 1, #O.sections do 
				if O.sections[i][2] >= O.currDepth then 
					if #O.sections[i][4] > 50 then
						sectionLines[#sectionLines + 1] = Menu.item(string.rep("\t", O.sections[i][2]) .. string.sub(O.sections[i][4], 1, 45) .. "...", { id =  O.sections[i][5] })
					else 
						sectionLines[#sectionLines + 1] = Menu.item(string.rep("\t", O.sections[i][2]) .. O.sections[i][4], { id =  O.sections[i][5] })
					end 
				end
			end 
			menu.lines = newLines -- FIXME
		end 
	end, { noremap = true }) 

	local progress = menu:map("n", "=", function()
		O.currDepth = O.currDepth + 1 

		local newLines = {} 
		for i = 1, #menu.lines do 
			--[[ 
			if O.sections[i][2] =< O.currDepth then 
				if (#O.sections[i][4] > 50) then
					newLines[#newLines + 1] = Menu.item(string.rep("\t", O.sections[i][2]) .. string.sub(O.sections[i][4], 1, 45) .. "...", { id =  O.sections[i][5] })
				else 
					newLines[#newLines + 1] = Menu.item(string.rep("\t", O.sections[i][2]) .. O.sections[i][4], { id =  O.sections[i][5] })
				end 
			end
			table.remove(menu.lines, i)
		end 

		if #newLines == 0 then
			O.currDepth = O.currDepth - 1 
			print "No deeper"
		else 
			menu.lines = newLines -- FIXME
			menu:unmount()
			menu:mount()
		end 
	end, { noremap = true }) 

	local open = menu:map("n", "<tab>", function () 
			-- TODO 
	end, { noremap = true }) 

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
		}, 
		buf_options = { 
			modifiable = true, 
			readonly = false
		},
		win_options = {
			modifiable = true, 
		} 
	})
	
	O.menu = menu 
	menu:mount() 
end 
]] 

function noterClose () 
	if O.open == true then 
		O.open = false 
		ui.nvim_buf_detach(O.buf) 
		ui.nvim_win_close(O.win, true) 
	end 
end 

function noterSnap () -- snap to current location
end 

function  noterRegress () 
	print "not deeper" 

	if O.currDepth == 0 then
		return
	else 
		O.currDepth = O.currDepth - 1
	end 

	local lines = {}
	for i = 1, #O.sections do 
		if O.sections[i][2] > O.currDepth  then 
			lines[#lines + 1] = string.rep('\t', O.sections[i][2] - O.depth) .. O.sections[i][4]	
		end 
	end 

	O.currLines = lines
	ui.nvim_buf_set_lines(O.buf, 0, 5, false, O.currLines) 
end 

function  noterProgress () 
	print "deeper" 
	O.currDepth = O.currDepth + 1

	local lines = {}
	for i = 1, #O.currSections do 
		if O.currSections[i][2] > O.currDepth then 
			lines[#lines + 1] = string.rep('\t', O.currSections[i][2] - O.depth) .. O.currSections[i][4]	
		end 
	end 

	O.currLines = lines
	ui.nvim_buf_set_lines(O.buf, 0, 5, false, O.currLines) 
end 

-- lul 
	-- lul 2
		-- lul 3
function  noterToggle () 
	local currLine = ui.nvim_win_get_cursor(O.win)[1]
	local point = O.sections[O.currSections[currLine][5]]

	if O.currSections[currLine + 1][2] == (point[2] + 1) then -- close point 
		for i = currLine + 1, #O.currSections do
			if O.currSections[i][2] <= point[2] then
				break
			end 
		end 

		table.remove(O.currSections, currLine + 1, i) 
		table.remove(O.currLines, currLine + 1, i) 

		ui.nvim_buf_set_lines(O.buf, 1, #O.currLines, false, O.currLines) 

	elseif O.sections[point[5] + 1][2] == point[2] + 1 then -- open point

		local newSections = {} 
		for i = point[5], #O.sections do 
			if O.sections[i][2] == O.currDepth + 1 then
				newSections[#newSections + 1] = O.sections[i]
			else
				break
			end 
		end
		table.insert(O.currSections, currLine, newSections) 

		local newLines = {} 
		for i = 1, #newSections do 
			newLines[#newLines + 1] = string.rep('\t', newSections[i][2] - O.currDepth) .. newSections[i][4]
			table.insert(O.currLines, currLine + i, newLines[#newLines]) 
		end 


		ui.nvim_buf_set_lines(O.buf, 1, #O.currLines, false, O.currLines) 
	else 
		print "no subsections" 
		return
	end 
end 

function noterSubmit () 
	local i = ui.nvim_win_get_cursor(O.win)[1]
	-- noterClose() 
	ui.nvim_win_set_cursor(O.NotesWindow, { O.currSections[i][3], O.currSections[i][2] + 1})	
end 

function minimalNav () 
	O.init() 
	O.refreshOutline() 

	ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, O.currLines) 

	O.open = true 
	O.win = ui.nvim_open_win(O.buf, true, 
   	{relative='win', row=3, col=70, width=50, height=100}
	) 
end 

