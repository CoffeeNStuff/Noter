local ui = vim.api
local set = require("set") 

local O = {
	initialized = false
} 

local sectionMarkers = { 
	{ '|', 1 }, 
	{ '||', 2 }, 
	{ '|||', 3 }, 
	{ '-', 4 }, 
	{ '~', 4 },
	{ '+', 4 }, 
	{ '??', 4 }, 
	{ '%', 4}, 
} 

table.sort(sectionMarkers, function (a, b) 
	return a[2] > b[2]
end) 

O.init = function () 
	O.NotesWindow = vim.api.nvim_get_current_win()
	O.txt = {}

	O.open = true 
	O.buf = ui.nvim_create_buf(false, false) 
	O.win = nil 

	O.sections = {} 
	O.currSections = {} 
	O.currLines = {} 

	O.depth = 0
	O.line = 0
	O.offset = 1
	O.index = 1

	O.currDepth = 0 
	O.currPri = 1
	O.fileName = vim.fn.expand('%') 

		ui.nvim_buf_set_keymap(O.buf, 'n', 'q', ':lua noterClose()<CR>', { silent = true }) 
		ui.nvim_buf_set_keymap(O.buf, 'n', '<esc>', ':lua noterClose()<CR>', { silent = true }) 

		ui.nvim_buf_set_keymap(O.buf, 'n', '<CR>', ':lua noterSubmit()<CR>', { silent = true }) 

		ui.nvim_buf_set_keymap(O.buf, 'n', '<Tab>', ':lua noterToggle()<CR>', { silent = true }) 
		ui.nvim_buf_set_keymap(O.buf, 'n', '=', ':lua noterProgress()<CR>', { silent = true }) 
		ui.nvim_buf_set_keymap(O.buf, 'n', '-', ':lua noterRegress()<CR>', { silent = true }) 
		ui.nvim_buf_set_keymap(O.buf, 'n', '0', ':lua noterRefreshLine()<CR>', { silent = true }) 

		ui.nvim_buf_set_keymap(O.buf, 'n', 's', ':lua noterSets()<CR>', { silent = true }) 
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

	local depth = 1
	for c in (string.sub(O.txt, start, O.offset - 2)):gmatch(".") do 
		if c == "\t" then 
			depth = depth + 1
		else 
			break
		end 
	end 

	O.line = O.line + 1
	return { 'unused', depth, O.line, string.sub(O.txt, start + depth - 1, O.offset - 2) } 
end 


O.refreshOutline = function() 
	O.txt = io.open(vim.fn.expand("%:p"), "r"):read("a") 
	O.sections = {} 

	while O.offset < #O.txt do 
		local newSection = O.getLine() 
		for i = 1, #sectionMarkers do 
			if string.sub(newSection[4],  1,  #sectionMarkers[i][1]) == sectionMarkers[i][1] then
				O.sections[#O.sections + 1] = {"Unused", newSection[2], newSection[3], newSection[4], #O.sections + 1, sectionMarkers[i][2]} -- to do 
				break
			end 
		end 
	end 

	O.currSections = {} 
	O.currLines = {} 
	local i = 0
	while i < #O.sections do
		i = i + 1
		if O.sections[i][6] == O.currPri then
			O.currSections[#O.currSections + 1] = O.sections[i] 
			O.currLines[#O.currLines + 1] = string.rep('\t', O.sections[i][2] - O.currDepth - 1) .. O.sections[i][4]

			i = i + 1
			while i < #O.sections do
				if O.sections[i][6] == O.currPri then 
					i = i - 1
					break
				else 
					i = i + 1
				end 
			end 

		elseif O.sections[i][6] < O.currPri then 
			break 		
		elseif O.sections[i][2] == O.currDepth then
			O.currSections[#O.currSections + 1] = O.sections[i] 
			O.currLines[#O.currLines + 1] = string.rep('\t', O.sections[i][2] - O.currDepth - 1) .. O.sections[i][4]
		end 
	end

	if O.currDepth == 0 then 
		if #O.fileName > 40 then 
			table.insert(O.currLines, 1, O.fileName .. ' ... ') 
			table.insert(O.currLines, 2, string.rep('-', 40)) 
		else 
			table.insert(O.currLines, 1, O.fileName) 
			table.insert(O.currLines, 2, string.rep('-', #O.fileName)) 
		end
	end 
end 


function  noterProgress () 

	local currLine = ui.nvim_win_get_cursor(O.win)[1] - 2	
	if currLine < 0 then	-- in the case cursor hovers non-section
		print 'no subsections' 
		return
	end 

	local headerPoint = O.currSections[currLine]  

	if O.sections[headerPoint[5] + 1][6] <= headerPoint[6] and O.sections[headerPoint[5] + 1][2] <= headerPoint[2] then
		print 'no subsections' 
		return
	end 

	local newSections = {} 

	local i = headerPoint[5] + 1
	while i < #O.sections do
		if O.sections[i][6] <= headerPoint[6] then
			break
		elseif O.sections[i][6] == headerPoint[6] + 1 then 
			newSections[#newSections + 1] = O.sections[i]
			i = i + 1
			while i < #O.sections do 
				if O.sections[i][6] <=  headerPoint[6] + 1 then
					break
				else 
					i = i + 1
				end 
			end 

		elseif O.sections[i][2] <= headerPoint[2] + 1 then
			newSections[#newSections + 1] = O.sections[i]
			i = i + 1
		else 
			i = i + 1
		end 
	end 
	O.currSections = newSections

	ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, {}) 
	O.currLines = {} 
	for i = 1, #newSections do 
		O.currLines[#O.currLines + 1] = string.rep('\t', newSections[i][2] - headerPoint[2]) .. newSections[i][4]
	end 

	if #headerPoint[4] > 40 then
		table.insert(O.currLines, 1, string.sub(headerPoint[4], 1, 35) .. ' ... ')
		table.insert(O.currLines, 2, string.rep('-', 40)) 
	else 
		table.insert(O.currLines, 1, headerPoint[4])
		table.insert(O.currLines, 2, string.rep('-', #O.currLines[1]))
	end 

	ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, O.currLines) 
end 

function noterRegress () 
	if  O.currSections[1][5] == 1 then 
		print 'No further back' 
		return
	end 
 

	local headerPoint = O.sections[O.currSections[1][5] - 1]

	local newSections = {}  

	local i = headerPoint[5]
	local newHeaderPoint = { "unused", 0, 0, O.fileName , 0, 0, 0 }
	while i > 0 do
		if O.sections[i][2] + 1 == headerPoint[2] or O.sections[i][6] + 1== headerPoint[6]  then
			newHeaderPoint = O.sections[i]
			break
		else 
			i = i - 1
		end 
	end 

	i = i + 1
	while i < #O.sections do
		if O.sections[i][6] <= newHeaderPoint[6] then
			break
		elseif O.sections[i][6] == newHeaderPoint[6] + 1 then 
			newSections[#newSections + 1] = O.sections[i]
			i = i + 1
			while i < #O.sections do 
				if O.sections[i][6] <=  newHeaderPoint[6] + 1 then
					break
				else 
					i = i + 1
				end 
			end 

		elseif O.sections[i][2] <= newHeaderPoint[2] + 1 then
			newSections[#newSections + 1] = O.sections[i]
			i = i + 1
		else 
			i = i + 1
		end 
	end 

	ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, {}) 
	O.currLines = {} 
	for i = 1, #newSections do 
		O.currLines[#O.currLines + 1] = string.rep('\t', newSections[i][2] - (newHeaderPoint[2] + 1)) .. newSections[i][4]
	end 
	
	if #newHeaderPoint[4] > 40 then
		table.insert(O.currLines, 1, string.sub(newHeaderPoint[4], 1, 35) .. ' ... ')
		table.insert(O.currLines, 2, string.rep('-', 40)) 
	else 
		table.insert(O.currLines, 1, newHeaderPoint[4])
		table.insert(O.currLines, 2, string.rep('-', #O.currLines[1]))
	end 


	O.currSections = newSections

	ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, O.currLines) 
end 


function  noterToggle () 
	local currLine = ui.nvim_win_get_cursor(O.win)[1] - 2
	local focusedPoint = O.currSections[currLine]

	if focusedPoint[5] == #O.sections then
		print 'no subsections' 
	 	return 	
	end 
	
	if currLine + 1 > #O.currSections  
		or O.currSections[currLine + 1][6] == focusedPoint[6]  
		or O.currSections[currLine + 1][2] == focusedPoint[2]   then  -- in case the point is closed 
		print 'opening lul' 
		
		local newSections = {} 

		local i = focusedPoint[5] + 1
		while i < #O.sections do
			if O.sections[i][6] <= focusedPoint[6] then
				break
			elseif O.sections[i][6] == focusedPoint[6] + 1 then 
				newSections[#newSections + 1] = O.sections[i]
				i = i + 1
				while i < #O.sections do 
					if O.sections[i][6] <=  focusedPoint[6] + 1 then
						break
					else 
						i = i + 1
					end 
				end 

			elseif O.sections[i][2] <= focusedPoint[2] + 1 then
				newSections[#newSections + 1] = O.sections[i]
				i = i + 1
			else 
				i = i + 1
			end 
		end 

		newLines = {} 
		for i = 1, #newSections do 
			newLines[#newLines + 1] = ' | ' .. string.rep('\t', newSections[i][2] - focusedPoint[2] + 1) .. newSections[i][4]
		end 

		for ii = 1, #newSections do
			table.insert(O.currSections, currLine + ii, newSections[ii]) 
			table.insert(O.currLines, currLine + ii + 2, newLines[ii]) 
		end 

		ui.nvim_buf_set_lines(O.buf, currLine + 2, currLine + 2, false, newLines) 

	else -- in case the point is open 
		print 'closing brug' 
			local i = currLine + 1

			while i < #O.currSections do 
				if O.currSections[i][6] <= focusedPoint[6] and O.currSections[i][2] <= focusedPoint[2]  then
					break
				else 
					i = i + 1
				end 
			end 

		
		for ii = currLine + 1, i - 1 do 
			table.remove(O.currSections, currLine + 1)
			table.remove(O.currLines, currLine + 3)
		end 
		
		ui.nvim_buf_set_lines(O.buf, currLine + 2, i + 1, false, {}) 
	end 
end 

function noterRefreshLine () 
	ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, O.currLines) 
end 

function noterSubmit () 
	local currLine = ui.nvim_win_get_cursor(O.win)[1] 
	noterClose() 
	if currLine <= 2 then
		return
	else 
		currLine = currLine - 2
		ui.nvim_win_set_cursor(O.NotesWindow, { O.currSections[currLine][3], O.currSections[currLine][2] + 1})	
	end 
end 

function noterClose () 
	if O.open == true then 
		O.open = false 
		ui.nvim_win_close(O.win, true) 
		ui.nvim_buf_delete(O.buf, { force = true }) 
	end 
end 

function noterOpen () 
	if O.open == true then 
		return
	end 
	O.init() 
	O.refreshOutline() 

	ui.nvim_buf_set_lines(O.buf, 0, #O.currLines, false, O.currLines) 

	O.open = true 
	O.win = ui.nvim_open_win(O.buf, true, 
   	{
			relative= 'win', 
			row= 0, 
			col= 120, 
			width= 75, 
			height= 20, 
			style = 'minimal', 
			border = 'single'
		}
	) 
end 

