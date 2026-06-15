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
