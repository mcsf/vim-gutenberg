let s:gutenberg_dir = expand('$GB_PATH')
let s:wp_dir        = expand('$WP_PATH')
let s:wp_tags       = expand('$WP_PATH/tags')

augroup gutenberg
	autocmd!
	autocmd VimEnter,DirChanged * call s:EnterGutenbergProject()
	autocmd BufEnter * call s:EnterGutenbergFile()
augroup END

function! s:EnterGutenbergProject()

	" A set of automations when working in the Gutenberg repository.
	if (getcwd() . '/') =~ '^' . expand(s:gutenberg_dir) . '/'

		" Include WordPress's own tags file so that we can look up Gutenberg
		" and WordPress identifiers alike.
		execute "set tags+=" . fnameescape(s:wp_tags)

		" Sort matching tags to prioritise tags closest to the current file.
		" This is determined by how many consecutives directories a tag's file
		" path has in common with the current file's path.
		set tagfunc=s:TagFuncNearestMatch

		" Regenerate Gutenberg's tags index in the background.
		let job = job_start('agtag', {
					\ "in_io": "null",
					\ "err_io": "null",
					\ "out_io": "file",
					\ "out_name": expand(s:gutenberg_dir . "/tags"),
					\ "exit_cb": function("s:HandleTagsJob", ["Gutenberg"]),
					\ "cwd": expand(s:gutenberg_dir),
					\ })

		" Regenerate WordPress's tags index in the background.
		let job = job_start('agtag', {
					\ "in_io": "null",
					\ "err_io": "null",
					\ "out_io": "file",
					\ "out_name": expand(s:wp_dir . "/tags"),
					\ "exit_cb": function("s:HandleTagsJob", ["WordPress"]),
					\ "cwd": expand(s:wp_dir),
					\ })

		set keywordprg=dash

	endif

endfunction

" Personal UI preferences when working specifically in Gutenberg.
function! s:EnterGutenbergFile()
	let fname = getbufinfo('%')[0].name
	if fname =~ '^' . expand(s:gutenberg_dir) || fname =~ '^' . expand(s:wp_dir)
		if fname =~ "__Tagbar__"
			return
		endif
		if get(g:, 'gutenberg_focus_mode', 1)
			setlocal laststatus& number&
		else
			setlocal laststatus=2
			setlocal number
		endif
	endif
endfunction

function! s:ToggleFocus()
	if get(g:, 'gutenberg_focus_mode')
		let g:gutenberg_focus_mode = 0
		echom "Focus mode disabled"
	else
		let g:gutenberg_focus_mode = 1
		echom "Focus mode enabled"
	endif
	windo call s:EnterGutenbergFile()
endfunction

let g:gutenberg_focus_mode = 1
call s:EnterGutenbergFile()

command! -nargs=0 GutenbergFocus call s:ToggleFocus()

function! s:HandleTagsJob(label, job, status)
	if a:status == 0
		echomsg a:label . " tags successfully regenerated."
	else
		echoerr "Could not regenerate " . a:label . " tags."
	endif
endfunction

function! s:TagFuncNearestMatch(pattern, flags, info)
	let pattern = a:pattern
	if (match(a:flags, "r") == -1)
		let pattern = "^" . pattern . "$"
	endif
	let tags = taglist(pattern)
	if (match(a:flags, "i") == -1)
		for tag in tags
			let tag.score = s:CommonPathScore(expand("%"), tag.filename)
		endfor
		call sort(tags, {a, b -> b.score - a.score})
	endif
	return tags
endfunction

function! s:CommonPathScore(a, b)
	let a = substitute(a:a, "^\./", "", "")
	let b = substitute(a:b, "^\./", "", "")

	let a = split(a, "/")
	let b = split(b, "/")
	let l = min([len(a), len(b)])
	let i = 0
	while i < l
		if a[i] != b[i]
			break
		endif
		let i = i + 1
	endwhile
	return i
endfunction
