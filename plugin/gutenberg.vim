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

" Like Vim's `K` lookup, but using `system()` for dispatch rather than `:!`
command! -nargs=0 GutenbergFindDocstring call s:FindDocstrings(expand('<cword>'))
function! s:FindDocstrings(symbol)
	echo system(printf('%s "%s"', &keywordprg, escape(a:symbol, '\')))
endfunction
