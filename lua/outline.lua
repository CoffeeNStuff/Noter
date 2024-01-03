-- search through outline of notes		
	-- open panel with contents 'loading ... ' 
	-- get file contents
		-- form into outline 
		-- display to panel 
			-- ability to jump to header/point 
				-- points and headers are colapsable in panel 

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
		ui.nvim_buf_set_keymap(O.buf, 'n', '=', ':lua noterProgress()<CR>', { silent = true }) 
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

-- TODO needs to check from longest to shortest length when implementing custom syntax 
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
		end 
		end 
	end 

	O.currSections = {} 
	O.currLines = {} 
	for i = 1, #O.sections do 
		if O.sections[i][2] == O.currDepth then
			O.currSections[#O.currSections + 1] = O.sections[i] 
			O.currLines[#O.currLines + 1] = string.rep('\t', O.sections[i][2] - O.currDepth) .. O.sections[i][4]
		end 
	end
end 

function noterClose () 
	if O.open == true then 
		O.open = false 
		ui.nvim_win_close(O.win, true) 
		ui.nvim_buf_delete(O.buf, { force = true }) 
	end 
end 

function noterSnap () -- snap to current location
end 

function  noterRegress () 
	if O.currDepth == 0 then
		print 'No further back' 
		return
	else 
		O.currDepth = O.currDepth - 1
	end 


	local newSections = {} 
	for i = 1, #O.sections do
		if O.sections[i][2] == O.currDepth  then 
			newSections[#newSections + 1] = O.sections[i]
		end
	end 

	local newLines = {}
	for i = 1, #newSections do 
		newLines[#newLines + 1] = string.rep('\t', newSections[i][2] - O.currDepth) .. newSections[i][4]	
	end 

	O.currSections = newSections
	O.currLines = newLines

	ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, {}) 
	ui.nvim_buf_set_lines(O.buf, 0, 5, false, O.currLines) 
end 

function  noterProgress () 

	local currPoint = O.currSections[ui.nvim_win_get_cursor(O.win)[1]] 
	local absPoint = O.sections[currPoint[5]]

	local newSections = {} 
	for i = absPoint[5] + 1, #O.sections do 
		if O.sections[i][2] == absPoint[2] + 1 then
			newSections[#newSections + 1] = O.sections[i]
		else
			break
		end 
	end

	local newLines = {} 
	for i = 1, #newSections do 
		newLines[#newLines + 1] = string.rep('\t', newSections[i][2] - (absPoint[2] + 1)) .. newSections[i][4]
	end 

	if #currPoint[4] > 40 then
		table.insert(newLines, 1, string.sub(currPoint[4], 1, 35) .. ' ... ')
		table.insert(newLines, 2, string.rep('-', 40)) 
	else 
		table.insert(newLines, 1, currPoint[4])
		table.insert(newLines, 2, string.rep('-', #newLines[1]))
	end 

	if #newSections == 0 then
		print 'no subsections' 
		return
	end 

	O.currDepth = O.currDepth + 1
	O.currSections = newSections
	O.currLines = newLines

	ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, {}) 
	ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, O.currLines) 

end 

-- lul 
	-- lul 2
		-- lul 3
function  noterToggle () 
	local currLine = ui.nvim_win_get_cursor(O.win)[1]
	local currPoint = O.currSections[currLine] 
	local absPoint = O.sections[currPoint[5]]

	print (O.sections[absPoint[5] + 1][4])

	if currLine == #O.currSections or O.currSections[currLine + 1][2] == currPoint[2] + 1 then -- close point 
		for i = currLine + 1, #O.currSections do
			if O.currSections[i][2] < currPoint[2] then
				break
			end 
		end 

		table.remove(O.currSections, currLine + 1, i) 
		table.remove(O.currLines, currLine + 1, i) 

		ui.nvim_buf_set_lines(O.buf, 1, #O.currLines, false, O.currLines) 

	elseif O.sections[absPoint[5] + 1][2] == absPoint[2] + 1 then -- open point

		local newSections = {} 
		for i = absPoint[5] + 1, #O.sections do 
			if O.sections[i][2] == O.currDepth + 1 then
				newSections[#newSections + 1] = O.sections[i]
			elseif O.sections[i][2] < currPoint[2] then
				break
			end 
		end


		local newLines = {} 
		for i = 1, #newSections do 
			newLines[#newLines + 1] = string.rep('\t', newSections[i][2] - O.currDepth) .. newSections[i][4]
		end 

		table.insert(O.currSections, currLine, newSections) 
		table.insert(O.currLines, currLine, newLines) 

		ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, O.currLines) 
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
   	{relative='win', row=0, col=120, width=75, height=20}
	) 
end 

