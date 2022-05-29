let s:gutenberg_dir = '~/gutenberg'
let s:wp_tags       = '/Applications/MAMP/htdocs/wpdev/tags'

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
