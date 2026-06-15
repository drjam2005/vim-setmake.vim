" setmake.vim - small helpers for building reliable 'makeprg' values.

if exists('g:loaded_setmake')
  finish
endif
let g:loaded_setmake = 1

command! -bar -nargs=+ MakeprgSet call setmake#CommandSet(<q-args>, 0)
command! -bar -nargs=+ MakeprgSetGlobal call setmake#CommandSet(<q-args>, 1)
command! -bar -nargs=+ MakeprgRaw call setmake#CommandRaw(<q-args>, 0)
command! -bar -nargs=+ MakeprgRawGlobal call setmake#CommandRaw(<q-args>, 1)
command! -bar MakeprgShow call setmake#Show()
command! -bar -nargs=* SetMake call setmake#Prompt(<q-args>)
