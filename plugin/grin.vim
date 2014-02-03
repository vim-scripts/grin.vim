" NOTE: You must, of course, install grin in your path or a virtualenv called
" grin
"
" Global install:
"
" $ sudo pip install grin
"
" User install:
"
" $ pip install --user grin
"
" In a Virtualenv:
"
" $ mkvirtualenv grin
" $ workon grin
" $ pip install grin

" Location of the grin utility
if !exists("g:grinprg")
  let s:grincommand = executable('grin') ? 'grin' : '$HOME/.virtualenvs/grin/bin/grin'
  let g:grinprg=s:grincommand." --emacs"
endif

if !exists("g:grin_apply_qmappings")
  let g:grin_apply_qmappings = !exists("g:grin_qhandler")
endif

if !exists("g:grin_apply_lmappings")
  let g:grin_apply_lmappings = !exists("g:grin_lhandler")
endif

if !exists("g:grin_qhandler")
  let g:grin_qhandler="botright copen"
endif

if !exists("g:grin_lhandler")
  let g:grin_lhandler="botright lopen"
endif

if !exists("g:grin_search_root")
  let g:grin_search_root = 1
endif

if !exists("g:grinhighlight")
  let g:grinhighlight = 1
endif

function! s:setcwd()
  let cph = expand('%:p:h', 1)
  if cph =~ '^.\+://' | retu | en
  for mkr in ['.git/', '.hg/', '.svn/', '.bzr/', '_darcs/', '.vimprojects']
    let wd = call('find'.(mkr =~ '/$' ? 'dir' : 'file'), [mkr, cph.';'])
    if wd != '' | let &acd = 0 | brea | en
  endfo
  exe 'lc!' fnameescape(wd == '' ? cph : substitute(wd, mkr.'$', '.', ''))
endfunction

function! s:Grin(cmd, args)
  redraw
  echo "Searching ..."

  " If no pattern is provided, search for the word under the cursor
  if empty(a:args)
    let l:grepargs = expand("<cword>")
  else
    let l:grepargs = a:args . join(a:000, ' ')
  end

  " Format, used to manage column jump
  if a:cmd =~# '-g$'
    let g:grinformat="%f"
  else
    let g:grinformat="%f:%l:%m"
  end

  let grepprg_bak=&grepprg
  let grepformat_bak=&grepformat
  let cwd_bak = expand('%:p:h', 1)
  if g:grin_search_root
    call s:setcwd()
  end
  try
    let &grepprg=g:grinprg
    let &grepformat=g:grinformat
    silent execute a:cmd . " " . escape(l:grepargs, '|')
  finally
    let &grepprg=grepprg_bak
    let &grepformat=grepformat_bak
    exe 'lc!' fnameescape(cwd_bak)
  endtry

  if a:cmd =~# '^l'
    exe g:grin_lhandler
    let l:apply_mappings = g:grin_apply_lmappings
  else
    exe g:grin_qhandler
    let l:apply_mappings = g:grin_apply_qmappings
  endif

  if l:apply_mappings
    exec "nnoremap <silent> <buffer> q :ccl<CR>"
    exec "nnoremap <silent> <buffer> t <C-W><CR><C-W>T"
    exec "nnoremap <silent> <buffer> T <C-W><CR><C-W>TgT<C-W><C-W>"
    exec "nnoremap <silent> <buffer> o <CR>"
    exec "nnoremap <silent> <buffer> go <CR><C-W><C-W>"
    exec "nnoremap <silent> <buffer> h <C-W><CR><C-W>K"
    exec "nnoremap <silent> <buffer> H <C-W><CR><C-W>K<C-W>b"
    exec "nnoremap <silent> <buffer> v <C-W><CR><C-W>H<C-W>b<C-W>J<C-W>t"
    exec "nnoremap <silent> <buffer> gv <C-W><CR><C-W>H<C-W>b<C-W>J"
  endif

  " If highlighting is on, highlight the search keyword.
  if g:grinhighlight
    let @/=a:args
    set hlsearch
  end

  redraw!
endfunction

function! s:GrinFromSearch(cmd, args)
  let search =  getreg('/')
  " translate vim regular expression to perl regular expression.
  let search = substitute(search,'\(\\<\|\\>\)','\\b','g')
  call s:Grin(a:cmd, '"' .  search .'" '. a:args)
endfunction

function! s:GetDocLocations()
    let dp = ''
    for p in split(&rtp,',')
        let p = p.'/doc/'
        if isdirectory(p)
            let dp = p.'*.txt '.dp
        endif
    endfor
    return dp
endfunction

function! s:GrinHelp(cmd,args)
    let args = a:args.' '.s:GetDocLocations()
    call s:Grin(a:cmd,args)
endfunction

command! -bang -nargs=* -complete=file Grin call s:Grin('grep<bang>',<q-args>)
command! -bang -nargs=* -complete=file GrinAdd call s:Grin('grepadd<bang>', <q-args>)
command! -bang -nargs=* -complete=file GrinFromSearch call s:GrinFromSearch('grep<bang>', <q-args>)
command! -bang -nargs=* -complete=file LGrin call s:Grin('lgrep<bang>', <q-args>)
command! -bang -nargs=* -complete=file LGrinAdd call s:Grin('lgrepadd<bang>', <q-args>)
command! -bang -nargs=* -complete=file GrinFile call s:Grin('grep<bang> -g', <q-args>)
command! -bang -nargs=* -complete=help GrinHelp call s:GrinHelp('grep<bang>',<q-args>)
command! -bang -nargs=* -complete=help LGrinHelp call s:GrinHelp('lgrep<bang>',<q-args>)
