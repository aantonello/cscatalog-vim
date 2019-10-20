" Vim plugin file
" Description: Simple Colorscheme Catalog builder.
" Version: 1.0
" Maintainer: Alessandro Antonello <antonello dot ale at gmail dot com>
" Last Change: 2013-01-02
" License: This script is in public domain.
" ============================================================================

" Just source this once or doesn't source it at all.
if exists('g:loaded_cscatalog')
    finish
endif
let g:loaded_cscatalog = 104

"" Commands
command -nargs=+ -complete=customlist,cs#catalog#listCategories CSAdd :call cs#catalog#addScheme(<f-args>)
command -nargs=1 -complete=customlist,cs#catalog#listCategories CSRem :call cs#catalog#removeSchemeFromCategory(<f-args>)
command -nargs=1 -complete=customlist,cs#catalog#listCategories CSDel :call cs#catalog#removeCategory(<f-args>)
command -nargs=+ -complete=customlist,cs#catalog#listCategories CSList :echo cs#catalog#listSchemes(<f-args>)

if v:version >= 704
    command -nargs=* -complete=color CSCat :echo cs#catalog#schemeCategories(<f-args>)
    command -nargs=? -complete=color CSFind :echo cs#catalog#findScheme(<f-args>)
    command -nargs=? -complete=color CSRemoveScheme :call cs#catalog#removeScheme(<f-args>)
else
    command -nargs=* CSCat :echo cs#catalog#schemeCategories(<f-args>)
    command -nargs=? CSFind :echo cs#catalog#findScheme(<f-args>)
    command -nargs=? CSRemoveScheme :call cs#catalog#removeScheme(<f-args>)
endif

" vim:ff=unix:fdm=marker:fmr=<<<,>>>
