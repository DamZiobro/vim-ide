" Vim syntax file
" Language:    hg graphlog output
" Maintainer:  Ludovic Chabant <ludovic@chabant.com>
" Filenames:   <none>

if exists("b:current_syntax")
    finish
endif

syn case match

syn match hggraphlogBranch         /^|\(\( .*\)\|$\)/he=s+1
syn match hggraphlogBranchMerge    /^|[\\\/]/
syn match hggraphlogNode           /^o .*/he=s+1

syn match hggraphlogBranch2        / |\(\( .*\)\|$\)/he=s+2          contained containedin=hggraphlogBranch,hggraphlogNode
syn match hggraphlogBranch2Merge   / |[\\\/]/                        contained containedin=hggraphlogBranch
syn match hggraphlogNode2          / o .*/he=s+2                     contained containedin=hggraphlogBranch

syn match hggraphlogBranch3        / | |\(\( .*\)\|$\)/ms=s+3,he=s+4 contained containedin=hggraphlogBranch2,hggraphlogNode2
syn match hggraphlogBranch3Merge   / | |[\\\/]/ms=s+3                contained containedin=hggraphlogBranch2
syn match hggraphlogNode3          / | o .*/ms=s+3,he=s+4            contained containedin=hggraphlogBranch2

syn match hggraphlogBranch4        / | | |\(\( .*\)\|$\)/ms=s+5,he=s+6 contained containedin=hggraphlogBranch3,hggraphlogNode3
syn match hggraphlogBranch4Merge   / | | |[\\\/]/ms=s+5                contained containedin=hggraphlogBranch3
syn match hggraphlogNode4          / | | o .*/ms=s+5,he=s+6            contained containedin=hggraphlogBranch3

syn match hggraphlogHead        /^@\s/he=e-1

hi def link hggraphlogBranch    hlLevel1
hi def link hggraphlogBranchMerge hlLevel1
hi def link hggraphlogNode      hlLevel1
hi def link hggraphlogBranch2   hlLevel2
hi def link hggraphlogBranch2Merge hlLevel2
hi def link hggraphlogNode2     hlLevel2
hi def link hggraphlogBranch3   hlLevel3
hi def link hggraphlogBranch3Merge hlLevel3
hi def link hggraphlogNode3     hlLevel3
hi def link hggraphlogBranch4   hlLevel4
hi def link hggraphlogBranch4Merge hlLevel4
hi def link hggraphlogNode4     hlLevel4
hi def link hggraphlogHead      PreProc

