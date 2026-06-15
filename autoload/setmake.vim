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

  botright 1new
  let b:setmake_source_bufnr = l:source_bufnr

  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  setlocal nowrap
  silent! file [SetMake]

  call setline(1, l:makeprg)
  normal! $
  setlocal nomodified

  nnoremap <buffer><silent> <CR> :<C-U>call setmake#EditAccept()<CR>
  inoremap <buffer><silent> <CR> <Esc>:<C-U>call setmake#EditAccept()<CR>
  nnoremap <buffer><silent> q :<C-U>call setmake#EditCancel()<CR>

  startinsert!
endfunction

function! setmake#EditCancel() abort
  setlocal nomodified
  close
endfunction

function! setmake#EditAccept() abort
  let l:source_bufnr = get(b:, 'setmake_source_bufnr', -1)
  let l:command = getline(1)

  if empty(l:command)
    echoerr 'setmake: command must not be empty'
    return
  endif
  if l:source_bufnr <= 0 || !bufexists(l:source_bufnr)
    echoerr 'setmake: source buffer no longer exists'
    return
  endif

  call setbufvar(l:source_bufnr, '&makeprg', l:command)
  setlocal nomodified
  close
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
