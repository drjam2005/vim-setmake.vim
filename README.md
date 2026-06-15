# vim-setmake.vim

> [!WARNING]
> This is purely vibe-coded lmao

A small Vim plugin for setting `makeprg` without hand-escaping paths.

## Install

Use any Vim plugin manager, or Vim's native package support:

```sh
mkdir -p ~/.vim/pack/local/start
ln -s /home/james/Projects/makeprg ~/.vim/pack/local/start/vim-setmake
vim -c 'helptags ~/.vim/pack/local/start/vim-setmake/doc' -c quit
```

## Usage

```vim
" Buffer-local makeprg.
:MakeprgSet make test

" Spaces are grouped with braces, not backslash escapes.
:MakeprgSet gcc -Wall %:p -o {build/my app}

" Use raw shell syntax when you need shell features.
:MakeprgRaw FOO=bar make test 2>&1

" Edit the current makeprg in a short bottom buffer.
:SetMake
```

`%`, `%:p`, `#`, and similar Vim file placeholders are preserved and get `:S`
added automatically, so Vim shell-escapes the expanded filename when `:make`
runs.

`:SetMake` opens a short terminal running your shell. Use shell completion as
usual, then press `<Enter>` to set the current line as `makeprg` for the Vim
session. Exit or close the terminal to cancel. This shell-backed mode currently
requires Bash.

From Vimscript, you can avoid command-line parsing entirely:

```vim
call setmake#Set(['gcc', '-Wall', '%:p', '-o', 'build/my app'])
call setmake#Set(['make', 'target with spaces'])
```
