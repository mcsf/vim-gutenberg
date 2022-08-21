let s:gutenberg_dir = '~/gutenberg'
let s:wp_tags       = '/Applications/MAMP/htdocs/wpdev/tags'
let s:__DIR__       = expand('<sfile>:p:h')

augroup gutenberg
	autocmd!
	autocmd VimEnter,DirChanged * call s:EnterGutenberg()
augroup END

function! s:EnterGutenberg()

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
					\ "exit_cb": "s:HandleTagsJob",
					\ "cwd": expand(s:gutenberg_dir),
					\ })

		" Look up a symbol's docstring if it's readily parseable in JS or PHP.
		" In the case of JS/TS, this acts as a fallback when TypeScript's LSP
		" fails to find documentation (LSP support is provided by the ALE
		" plugin.)
		let &keywordprg = fnameescape(s:__DIR__ . '/find-docstrings')
		nnoremap <Leader>K :GutenbergFindDocstring<cr>

		" Personal UI preferences when working specifically in Gutenberg.
		set laststatus=2
		set number

	endif

endfunction

function! s:HandleTagsJob(job, status)
	if a:status == 0
		echomsg "Gutenberg tags successfully regenerated."
	else
		echoerr "Could not regenerate Gutenberg tags."
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
	let a = split(a:a, "/")
	let b = split(a:b, "/")
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

" Like Vim's `K` lookup, but using `system()` for dispatch rather than `:!`
command! -nargs=0 GutenbergFindDocstring call s:FindDocstrings(expand('<cword>'))
function! s:FindDocstrings(symbol)
	echo system(printf('%s "%s"', &keywordprg, escape(a:symbol, '\')))
endfunction
