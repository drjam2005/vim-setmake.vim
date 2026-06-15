" Build shell-safe 'makeprg' values from argument lists.

function! setmake#Set(argv, ...) abort
  if type(a:argv) != v:t_list || empty(a:argv)
    throw 'setmake: argv must be a non-empty List'
  endif

  let l:opts = get(a:, 1, {})
  if type(l:opts) != v:t_dict
    throw 'setmake: options must be a Dictionary'
  endif

  let l:cmd = join(map(copy(a:argv), 's:Arg(v:val)'), ' ')

  if get(l:opts, 'global', 0)
    let &makeprg = l:cmd
  else
    let &l:makeprg = l:cmd
  endif

  return l:cmd
endfunction

function! setmake#Raw(command, ...) abort
  if empty(a:command)
    throw 'setmake: command must not be empty'
  endif

  let l:opts = get(a:, 1, {})
  if type(l:opts) != v:t_dict
    throw 'setmake: options must be a Dictionary'
  endif

  if get(l:opts, 'global', 0)
    let &makeprg = a:command
  else
    let &l:makeprg = a:command
  endif

  return a:command
endfunction

function! setmake#CommandSet(args, global) abort
  call setmake#Set(s:Tokenize(a:args), {'global': a:global})
  call setmake#Show()
endfunction

function! setmake#CommandRaw(args, global) abort
  call setmake#Raw(a:args, {'global': a:global})
  call setmake#Show()
endfunction

function! setmake#Edit() abort
  let l:source_bufnr = bufnr('%')
  let l:makeprg = &makeprg
  let l:shell = empty($SHELL) ? &shell : $SHELL

  if fnamemodify(l:shell, ':t') !=# 'bash'
    echoerr 'setmake: terminal SetMake currently requires bash'
    return
  endif

  let l:rcfile = tempname()
  call writefile([
        \ 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi',
        \ 'set +o history',
        \ 'PS1="makeprg> "',
        \ '__setmake_accept() {',
        \ '  local line json',
        \ '  line=${READLINE_LINE}',
        \ '  json=${line//\\/\\\\}',
        \ '  json=${json//\"/\\\"}',
        \ '  json=${json//$''\n''/\\n}',
        \ '  json=${json//$''\r''/\\r}',
        \ '  json=${json//$''\t''/\\t}',
        \ '  printf ''\033]51;["call","SetmakeTapi_Accept",["%s"]]\007'' "$json"',
        \ '  exit',
        \ '}',
        \ 'bind -x ''"\C-m":__setmake_accept''',
        \ ], l:rcfile)

  botright 3new
  let b:setmake_source_bufnr = l:source_bufnr
  let b:setmake_rcfile = l:rcfile

  let l:term_bufnr = term_start([l:shell, '--rcfile', l:rcfile, '-i'], {
        \ 'curwin': 1,
        \ 'term_name': '[SetMake]',
        \ 'term_finish': 'close',
        \ 'term_kill': 'kill',
        \ 'norestore': 1,
        \ 'term_api': 'SetmakeTapi_',
        \ })

  if l:term_bufnr <= 0
    call delete(l:rcfile)
    echoerr 'setmake: failed to open terminal'
    return
  endif

  call setbufvar(l:term_bufnr, 'setmake_source_bufnr', l:source_bufnr)
  call setbufvar(l:term_bufnr, 'setmake_rcfile', l:rcfile)
  augroup setmake_edit
    autocmd! * <buffer>
    autocmd BufWipeout <buffer> call setmake#EditCleanup(expand('<abuf>'))
  augroup END

  call timer_start(100, {-> term_sendkeys(l:term_bufnr, l:makeprg)})
  startinsert
endfunction

function! setmake#EditCleanup(bufnr) abort
  let l:rcfile = getbufvar(str2nr(a:bufnr), 'setmake_rcfile', '')
  if !empty(l:rcfile)
    call delete(l:rcfile)
  endif
endfunction

function! SetmakeTapi_Accept(bufnr, arglist) abort
  let l:source_bufnr = getbufvar(a:bufnr, 'setmake_source_bufnr', -1)
  let l:command = get(a:arglist, 0, '')

  if empty(l:command)
    echoerr 'setmake: command must not be empty'
    return
  endif
  if l:source_bufnr <= 0 || !bufexists(l:source_bufnr)
    echoerr 'setmake: source buffer no longer exists'
    return
  endif

  let &g:makeprg = l:command
  call setbufvar(l:source_bufnr, '&makeprg', l:command)
  echo 'makeprg=' . l:command
endfunction

function! setmake#Show() abort
  echo 'makeprg=' . &l:makeprg
endfunction

function! s:Tokenize(text) abort
  let l:tokens = []
  let l:token = ''
  let l:in_braces = 0
  let l:i = 0

  while l:i < strlen(a:text)
    let l:ch = a:text[l:i]

    if l:in_braces
      if l:ch ==# '}'
        let l:in_braces = 0
      else
        let l:token .= l:ch
      endif
    elseif l:ch ==# '{'
      let l:in_braces = 1
    elseif l:ch =~# '\s'
      if !empty(l:token)
        call add(l:tokens, l:token)
        let l:token = ''
      endif
    else
      let l:token .= l:ch
    endif

    let l:i += 1
  endwhile

  if l:in_braces
    throw 'setmake: unmatched { in arguments'
  endif
  if !empty(l:token)
    call add(l:tokens, l:token)
  endif
  if empty(l:tokens)
    throw 'setmake: missing command'
  endif

  return l:tokens
endfunction

function! s:Arg(value) abort
  if type(a:value) != v:t_string
    throw 'setmake: every argv item must be a String'
  endif

  if s:IsMakePlaceholder(a:value)
    return s:ShellSafePlaceholder(a:value)
  endif

  return shellescape(a:value)
endfunction

function! s:IsMakePlaceholder(value) abort
  return a:value =~# '^\s*\(%\|#\)\%(<\)\?\%(:[[:alnum:]_:.~-]\+\)*\s*$'
endfunction

function! s:ShellSafePlaceholder(value) abort
  if a:value =~# ':\zsS\ze\%(:\|$\)'
    return a:value
  endif
  return a:value . ':S'
endfunction
