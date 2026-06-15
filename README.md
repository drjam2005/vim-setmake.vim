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

`:SetMake` edits the final `makeprg` string directly. Press `<Enter>` to set it
for the Vim session, or `q` in Normal mode to close without changing it.

From Vimscript, you can avoid command-line parsing entirely:

```vim
call setmake#Set(['gcc', '-Wall', '%:p', '-o', 'build/my app'])
call setmake#Set(['make', 'target with spaces'])
```
