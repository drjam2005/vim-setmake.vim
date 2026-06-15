" Build shell-safe 'makeprg' values from argument lists.

let s:root_markers = [
      \ '.git',
      \ 'Makefile',
      \ 'makefile',
      \ 'package.json',
      \ 'pyproject.toml',
      \ 'Cargo.toml',
      \ 'go.mod',
      \ ]
let s:prompts = {}

function! setmake#Set(argv, ...) abort
  if type(a:argv) != v:t_list || empty(a:argv)
    throw 'makeprg: argv must be a non-empty List'
  endif

  let l:opts = get(a:, 1, {})
  if type(l:opts) != v:t_dict
    throw 'makeprg: options must be a Dictionary'
  endif

  let l:cmd = join(map(copy(a:argv), 's:Arg(v:val)'), ' ')
  let l:cwd = s:ResolveCwd(get(l:opts, 'cwd', 'project'))
  if !empty(l:cwd)
    let l:cmd = s:CdPrefix(l:cwd) . l:cmd
  endif

  if get(l:opts, 'global', 0)
    let &makeprg = l:cmd
  else
    let &l:makeprg = l:cmd
    let b:setmake_argv = copy(a:argv)
    let b:setmake_cwd = l:cwd
  endif

  return l:cmd
endfunction

function! setmake#Raw(command, ...) abort
  if empty(a:command)
    throw 'makeprg: command must not be empty'
  endif

  let l:opts = get(a:, 1, {})
  if type(l:opts) != v:t_dict
    throw 'makeprg: options must be a Dictionary'
  endif

  let l:cmd = a:command
  let l:cwd = s:ResolveCwd(get(l:opts, 'cwd', 'project'))
  if !empty(l:cwd)
    let l:cmd = s:CdPrefix(l:cwd) . l:cmd
  endif

  if get(l:opts, 'global', 0)
    let &makeprg = l:cmd
  else
    let &l:makeprg = l:cmd
    let b:setmake_argv = []
    let b:setmake_cwd = l:cwd
  endif

  return l:cmd
endfunction

function! setmake#CommandSet(args, global) abort
  let l:parsed = s:ParseCommand(a:args)
  call setmake#Set(l:parsed.argv, extend(l:parsed.opts, {'global': a:global}))
  call setmake#Show()
endfunction

function! setmake#CommandRaw(args, global) abort
  let l:parsed = s:ParseCommand(a:args)
  call setmake#Raw(join(l:parsed.argv, ' '), extend(l:parsed.opts, {'global': a:global}))
  call setmake#Show()
endfunction

function! setmake#Show() abort
  echo 'makeprg=' . &l:makeprg
  if exists('b:setmake_cwd') && !empty(b:setmake_cwd)
    echo 'makeprg cwd=' . b:setmake_cwd
  endif
endfunction

function! setmake#Prompt(initial) abort
  let l:initial = empty(a:initial) ? s:PreviousInput() : a:initial

  if !exists('*popup_create')
    let l:input = input('makeprg> ', l:initial)
    if !empty(l:input)
      call setmake#CommandSet(l:input, 0)
    endif
    return
  endif

  let l:width = min([max([50, &columns / 2]), &columns - 8])
  let l:line = max([1, (&lines / 2) - 2])
  let l:col = max([1, (&columns - l:width) / 2])
  let l:winid = popup_create([], {
        \ 'title': ' SetMake ',
        \ 'line': l:line,
        \ 'col': l:col,
        \ 'minwidth': l:width,
        \ 'maxwidth': l:width,
        \ 'padding': [1, 2, 1, 2],
        \ 'border': [],
        \ 'mapping': 0,
        \ 'filter': function('setmake#PromptFilter'),
        \ })

  let s:prompts[l:winid] = {
        \ 'text': l:initial,
        \ 'message': 'Enter to set, Esc to cancel',
        \ }
  call s:RenderPrompt(l:winid)
endfunction

function! setmake#PromptFilter(winid, key) abort
  if !has_key(s:prompts, a:winid)
    return 0
  endif

  if a:key ==# "\<Esc>" || a:key ==# "\<C-C>"
    call remove(s:prompts, a:winid)
    call popup_close(a:winid)
    return 1
  endif

  if a:key ==# "\<CR>" || a:key ==# "\<NL>"
    let l:text = s:prompts[a:winid].text
    call remove(s:prompts, a:winid)
    call popup_close(a:winid)
    if !empty(l:text)
      try
        call setmake#CommandSet(l:text, 0)
      catch
        echohl ErrorMsg
        echomsg v:exception
        echohl None
      endtry
    endif
    return 1
  endif

  if a:key ==# "\<BS>" || a:key ==# "\<C-H>"
    let s:prompts[a:winid].text = s:Backspace(s:prompts[a:winid].text)
    call s:RenderPrompt(a:winid)
    return 1
  endif

  if a:key ==# "\<C-U>"
    let s:prompts[a:winid].text = ''
    call s:RenderPrompt(a:winid)
    return 1
  endif

  if strlen(a:key) == 1 && char2nr(a:key) >= 32
    let s:prompts[a:winid].text .= a:key
    call s:RenderPrompt(a:winid)
    return 1
  endif

  return 1
endfunction

function! s:ParseCommand(args) abort
  let l:tokens = s:Tokenize(a:args)
  let l:opts = {}

  while !empty(l:tokens)
    let l:token = l:tokens[0]
    if l:token =~# '^-cwd='
      let l:opts.cwd = l:token[5:]
      call remove(l:tokens, 0)
    elseif l:token ==# '-global'
      let l:opts.global = 1
      call remove(l:tokens, 0)
    else
      break
    endif
  endwhile

  if empty(l:tokens)
    throw 'makeprg: missing command'
  endif

  return {'argv': l:tokens, 'opts': l:opts}
endfunction

function! s:PreviousInput() abort
  if exists('b:setmake_argv') && !empty(b:setmake_argv)
    return join(map(copy(b:setmake_argv), 's:PromptArg(v:val)'), ' ')
  endif
  return ''
endfunction

function! s:PromptArg(value) abort
  if a:value =~# '\s'
    return '{' . substitute(a:value, '[{}]', '', 'g') . '}'
  endif
  return a:value
endfunction

function! s:RenderPrompt(winid) abort
  if !has_key(s:prompts, a:winid)
    return
  endif

  let l:state = s:prompts[a:winid]
  let l:line = '> ' . l:state.text . ' '
  call popup_settext(a:winid, [
        \ 'Make command',
        \ l:line,
        \ l:state.message,
        \ ])
endfunction

function! s:Backspace(text) abort
  if empty(a:text)
    return ''
  endif
  return strpart(a:text, 0, strlen(a:text) - 1)
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
    throw 'makeprg: unmatched { in arguments'
  endif
  if !empty(l:token)
    call add(l:tokens, l:token)
  endif

  return l:tokens
endfunction

function! s:Arg(value) abort
  if type(a:value) != v:t_string
    throw 'makeprg: every argv item must be a String'
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

function! s:ResolveCwd(cwd) abort
  if a:cwd ==# '' || a:cwd ==# 'none'
    return ''
  endif
  if a:cwd ==# 'project'
    return s:FindRoot()
  endif
  if a:cwd ==# 'buffer'
    let l:dir = expand('%:p:h')
    return empty(l:dir) ? getcwd() : l:dir
  endif
  if a:cwd ==# '.'
    return getcwd()
  endif
  return fnamemodify(a:cwd, ':p')
endfunction

function! s:FindRoot() abort
  let l:start = expand('%:p:h')
  if empty(l:start)
    let l:start = getcwd()
  endif

  let l:dir = fnamemodify(l:start, ':p')
  while 1
    for l:marker in s:root_markers
      let l:path = l:dir . '/' . l:marker
      if filereadable(l:path) || isdirectory(l:path)
        return l:dir
      endif
    endfor

    let l:parent = fnamemodify(l:dir, ':h')
    if l:parent ==# l:dir
      return getcwd()
    endif
    let l:dir = l:parent
  endwhile
endfunction

function! s:CdPrefix(cwd) abort
  if has('win32') || has('win64')
    return 'cd /d ' . shellescape(a:cwd) . ' && '
  endif
  return 'cd ' . shellescape(a:cwd) . ' && '
endfunction
