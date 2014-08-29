" Vim syntax file
" Language:     hg qseries 'augmented' output
" Maintainer:   Ludovic Chabant <ludovic@chabant.com>
" Filenames:    <none>

if exists("b:current_syntax")
    finish
endif

syn case match

syn match hgqseriesApplied      /^\*[^:]+: /
syn match hgqseriesUnapplied    /^[^\*].*: /

hi def link hgqseriesApplied    Identifier
hi def link hgqseriesUnapplied  Comment

