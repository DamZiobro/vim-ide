" Vim syntax file
" Language:    hg log output
" Maintainer:  Ludovic Chabant <ludovic@chabant.com>
" Filenames:   <none>

if exists("b:current_syntax")
    finish
endif

syn case match

syn match hglogRev              '\v^[0-9]+'
syn match hglogNode             '\v:[a-f0-9]{6,} 'hs=s+1,me=e-1
syn match hglogBookmark         '\v \+[^ ]+ 'ms=s+1,me=e-1 contains=hglogBookmarkPlus
syn match hglogTag              '\v #[^ ]+ 'ms=s+1,me=e-1 contains=hglogTagSharp
syn match hglogAuthorAndAge     '\v\(by .+, .+\)$'

syn match hglogBookmarkPlus     '\v\+' contained conceal
syn match hglogTagSharp         '\v#'  contained conceal

hi def link hglogRev            Identifier
hi def link hglogNode           PreProc
hi def link hglogBookmark       Statement
hi def link hglogTag            Constant
hi def link hglogAuthorAndAge   Comment
