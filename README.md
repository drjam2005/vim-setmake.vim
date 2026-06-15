# vim-setmake.vim

> [!WARNING]
> This is purely vibe-coded lmao

A small Vim plugin for setting `makeprg` without hand-escaping paths or losing
track of relative directories when `autochdir` is enabled.

## Install

Use any Vim plugin manager, or Vim's native package support:

```sh
mkdir -p ~/.vim/pack/local/start
ln -s /home/james/Projects/makeprg ~/.vim/pack/local/start/vim-setmake
vim -c 'helptags ~/.vim/pack/local/start/vim-setmake/doc' -c quit
```

## Usage

```vim
" Buffer-local makeprg, pinned to the detected project root.
:MakeprgSet make test

" Spaces are grouped with braces, not backslash escapes.
:MakeprgSet gcc -Wall %:p -o {build/my app}

" Pin relative paths to the current buffer's directory.
:MakeprgSet -cwd=buffer make

" Use raw shell syntax when you need shell features.
:MakeprgRaw -cwd=project FOO=bar make test 2>&1

" Open a small Vim popup prompt and type the command there.
:SetMake
```

`%`, `%:p`, `#`, and similar Vim file placeholders are preserved and get `:S`
added automatically, so Vim shell-escapes the expanded filename when `:make`
runs.

From Vimscript, you can avoid command-line parsing entirely:

```vim
call setmake#Set(['gcc', '-Wall', '%:p', '-o', 'build/my app'])
call setmake#Set(['make', 'target with spaces'], {'cwd': 'project'})
```
