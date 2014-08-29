" Vim syntax file
" Language:     hg status output
" Maintainer:   Ludovic Chabant <ludovic@chabant.com>
" Filenames:    ^hg-status-*.txt

if exists("b:current_syntax")
    finish
endif

syn case match

syn match hgstatusModified      "^M\s.*"
syn match hgstatusAdded         "^A\s.*"
syn match hgstatusRemoved       "^R\s.*"
syn match hgstatusClean         "^C\s.*"
syn match hgstatusMissing       "^?\s.*"
syn match hgstatusNotTracked    "^!\s.*"
syn match hgstatusIgnored       "^I\s.*"

hi def link hgstatusModified    Identifier
hi def link hgstatusAdded       Statement
hi def link hgstatusRemoved     PreProc
hi def link hgstatusClean       Constant
hi def link hgstatusMissing     Error
hi def link hgstatusNotTracked  Todo
hi def link hgstatusIgnored     Ignore
hi def link hgstatusFileName    Constant

