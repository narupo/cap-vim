""
" cap.vim
"
" Vim plugin for cap.
"
" License: MIT
" Author: narupo
"

""
" CapGetYank
"
" Based code from http://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript by xolox
"
" Licenses:
"
"	public domain (inherit)
"
" Examples:
"
"	let ynk = CapGetYank()
"	echo ynk
"
function! CapGetYank()
	let [lnum1, col1] = getpos("'<")[1:2]
	let [lnum2, col2] = getpos("'>")[1:2]
	let lines = getline(lnum1, lnum2)
	if !len(lines)
		return '' " Not found yank
	endif
	let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
	let lines[0] = lines[0][col1 - 1:]
	return join(lines, "\n")
endfunction

""
" CapParseLine
"
" Parse string line. And convert to cap's command line
"
" @param string line
" @return list [str, int] [cmdline, atpos]
"
function! CapParseLine(line)
	let len = strlen(a:line)
	let m = 0
	let atpos = -1
	let cmdline = ''

	for i in range(len)
		let c = a:line[i]
		"echo m ':' c

		if m == 0 " First
			if c ==? '@'
				let m = 10
				let atpos = i+1
			endif
		elseif m == 10 " @
			let cmdline .= c
		endif
	endfor

	if strlen(cmdline) == 0
		echo "cap vim: Invalid command line"
		return [cmdline, atpos]
	endif

	if cmdline[0:3] != 'cap '
		let cmdline = 'cap ' . cmdline
	endif

	return [cmdline, atpos]
endfunction

""
" CapRun
"
" Run cap
"
"
function! CapRun()
	" Line to cap command line
	let line = getline('.')
	let [cmdline, atpos] = CapParseLine(line)
	if !strlen(cmdline)
		echo 'cap vim: Failed to run'
		return
	endif

	" Execute cap command
	let ynk = CapGetYank()
	if strlen(ynk)
		let res = system('echo ' . shellescape(ynk) . ' | ' . cmdline)
	else
		let res = system(cmdline)
	endif

	" Delete command line on buffer
	let nrow = line('.')
	call cursor(nrow, atpos)
	execute ":normal d$"

	" Insert result of cap
	let oldpos = getpos('.')
	execute ":set paste"
	execute ":normal a" . res
	call setpos('.', oldpos)
endfunction

nmap <silent> <C-[> :call CapRun()<CR>
