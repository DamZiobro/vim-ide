syn match MercenaryblameBoundary  "^\^"
syn match MercenaryblameBlank     "^\s\+\s\@=" nextgroup=MercenaryblameAuthor skipwhite
syn match MercenaryblameAuthor    "\w\+" nextgroup=MercenaryblameNumber skipwhite
syn match MercenaryblameNumber    "\d\+" nextgroup=MercenaryblameChangeset skipwhite
syn match MercenaryblameChangeset "[a-f0-9]\{12\}" nextgroup=MercenaryblameDate skipwhite
syn match MercenaryblameDate      "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}"
hi def link MercenaryblameAuthor    Keyword
hi def link MercenaryblameNumber    Number
hi def link MercenaryblameChangeset Identifier
hi def link MercenaryblameDate      PreProc
