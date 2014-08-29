" Vim syntax file
" Language:     hg commit file
" Maintainer:   Pierre Bourdon <delroth@gmail.com>
" Filenames:    ^hg-editor-*.txt
" Last Change:  2010 Jun 13

" Some parts of the code by Dan LaMotte <lamotte85@gmail.com>

if exists("b:current_syntax")
    finish
endif

syn case match
syn sync minlines=50

if has("spell")
    syn spell toplevel
endif

syn match   hgcommitFirstline   "\%^.*"         nextgroup=hgcommitBlank skipnl
syn match   hgcommitSummary     "^.\{0,78\}"    contained containedin=hgcommitFirstline nextgroup=hgcommitOverflow contains=@Spell
syn match   hgcommitOverflow    ".*"            contained contains=@Spell
syn match   hgcommitBlank       "^HG:\@!.*"     contained contains=@Spell

syn match   hgcommitComment     "^HG:.*"

syn match hgcommitOnBranch  "\%(^HG: \)\@<=\<branch\> '" contained containedin=hgcommitComment nextgroup=hgcommitBranch
syn match hgcommitBranch    "[^']\+" contained
syn match hgcommitAdded     "\%(^HG: \)\@<=\<added\>" contained containedin=hgcommitComment nextgroup=hgcommitFile
syn match hgcommitChanged   "\%(^HG: \)\@<=\<changed\>" contained containedin=hgcommitComment nextgroup=hgcommitFile
syn match hgcommitRemoved   "\%(^HG: \)\@<=\<removed\>" contained containedin=hgcommitComment nextgroup=hgcommitFile
syn match hgcommitFile      " \S\+" contained containedin=hgcommitAdded,hgcommitChanged

hi def link hgcommitSummary     Keyword
hi def link hgcommitOverflow    Error
hi def link hgcommitBlank       Error

hi def link hgcommitComment     Comment
hi def link hgcommitOnBranch    Comment
hi def link hgcommitBranch      Special
hi def link hgcommitOnBranchEnd Comment
hi def link hgcommitAdded       Type
hi def link hgcommitChanged     Type
hi def link hgcommitRemoved     Type
hi def link hgcommitFile        Constant

