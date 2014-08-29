" Vim syntax file
" Language:     hg annotate output
" Maintainer:   Ludovic Chabant <ludovic@chabant.com>
" Filenames:    <none>

if exists("b:current_syntax")
    finish
endif

syn case match

syn match hgannotateAnnotation '\v[^\:]+\:'he=e-1
syn match hgannotateAuthor    '\v^[^ ]+' containedin=hgannotateAnnotation
syn match hgannotateNumber    '\v\s\d+\s'ms=s+1,me=e-1 containedin=hgannotateAnnotation
syn match hgannotateChangeset '\v\s[a-f0-9]{12}\s'ms=s+1,me=e-1 containedin=hgannotateAnnotation
syn match hgannotateDate      '\v\s[0-9]{4}\-[0-9]{2}\-[0-9]{2}\:'ms=s+1,me=e-1 containedin=hgannotateAnnotation
syn match hgannotateLongDate  '\v\s\w{3} \w{3} \d\d \d\d\:\d\d\:\d\d \d{4} [\+\-]?\d{4}\:'ms=s+1,me=e-1 containedin=hgannotateAnnotation

hi def link hgannotateAuthor    Keyword
hi def link hgannotateNumber    Number
hi def link hgannotateChangeset Identifier
hi def link hgannotateDate      PreProc
hi def link hgannotateLongDate  PreProc

