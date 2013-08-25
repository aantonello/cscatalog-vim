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

"" Local Variables
let s:storage_folder = ''
if exists('g:csc_StorageFolder')
    let s:storage_folder = expand(g:csc_StorageFolder)
endif

"" Exported Functions 
" s:ListCategories(ArgLead, CmdLine, CursorPos) <<<
" List the current categories.
" @returns List of the current categories.
" ============================================================================
fun s:ListCategories(ArgLead, CmdLine, CursorPos)
    if !s:CheckConfig()
        return []
    endif

    " The result of globpath() is a list of new-line separated paths.
    let l:categoryList = s:CatalogList()

    " We need only the category names. Not paths.
    call map(l:categoryList, 'fnamemodify(v:val, ":t")')

    " filtering the arg-lead, if needed
    if strlen(a:ArgLead) > 0
        call filter(l:categoryList, 'v:val =~? "^'.a:ArgLead.'"')
    endif
    call sort(l:categoryList)

    return l:categoryList

endfun " >>>
" s:AddToCategory(...) <<<
" Add the current colorscheme to a category.
" @param ... A list of category names to add the current scheme.
" @returns Nothing.
" ============================================================================
fun s:AddToCategory(...)
    if !s:CheckConfig()
        return
    endif

    let l:scheme = exists('g:colors_name') ? g:colors_name : ''
    if strlen(l:scheme) == 0
        call s:EchoMsg('error', 'g:colors_name option not set.')
        return
    endif

    " Open the category file. It has all schemes pertaining to that category.
    for cName in a:000
        let l:categoryFile = s:OpenCatFile(cName)
        if empty(l:categoryFile)
            call add(l:categoryFile, '')        " First line reserved to a description.
            call add(l:categoryFile, l:scheme)
        else
            " Only if the color scheme is not in that file.
            if index(l:categoryFile, l:scheme) < 0
                call add(l:categoryFile, l:scheme)
            endif
        endif

        " Write the category file.
        call s:WriteCatFile(cName, l:categoryFile)
    endfor

endfun " >>>
" s:RemoveFromCategory(cname, ...) <<<
" Remove the current color scheme from a category.
" @param cname The category name.
" @returns Nothing.
" ============================================================================
fun s:RemoveFromCategory(cname, ...)
    if !s:CheckConfig()
        return
    endif

    let l:schemeList = s:OpenCatFile(a:cname)
    if empty(l:schemeList)
        " Nothint to do
        return
    endif

    let l:scheme = g:colors_name
    if a:0 > 0
        let l:scheme = a:1
    endif

    " Filter the list
    call filter(l:schemeList, 'v:val !=? "'.l:scheme.'"')

    " Write the file again
    call s:WriteCatFile(a:cname, l:schemeList)
endfun " >>>
" s:RemoveCategory(cname) <<<
" Removes a category from the catalog.
" @param cname Category name.
" @returns Nothing.
" ============================================================================
fun s:RemoveCategory(cname)
    if !s:CheckConfig()
        return
    endif

    let l:fileName = s:storage_folder.'/'.a:cname
    if !s:Confirm('Are you sure to remove the file: "'.l:fileName.'"?')
        return
    endif
    call delete(l:fileName)
endfun " >>>
" s:ListCategoriesFor(...) <<<
" List the categories of a colorscheme.
" @param ... A colorscheme name, if not passed the current color will be used.
" @returns The list of categories where the colorscheme appears.
" ============================================================================
fun s:ListCategoriesFor(...)
    if !s:CheckConfig()
        return ''
    endif

    let l:sname = ""
    let l:catalog = s:CatalogList()
    let l:schemes = []
    let l:categories = []

    if a:0 > 0 && strlen(a:1) > 0
        let l:sname = a:1
    else
        let l:sname = g:colors_name
    endif

    " We need only names, not paths.
    call map(l:catalog, 'fnamemodify(v:val, ":t")')

    for category in l:catalog
        let l:schemes = s:OpenCatFile(category)
        if index(l:schemes, l:sname, 1, 1) >= 0
            call add(l:categories, category)
        endif
    endfor

    if empty(l:categories)
        return '"'.l:sname.'" not found in catalog'
    endif

    return join(l:categories, '    ')
endfun " >>>
" s:ListSchemes(cname, ...) <<<
" List all color schemes within a category.
" @param cname Category name
" @returns The list of color schemes in the category or an empty string.
" ============================================================================
fun s:ListSchemes(cname, ...)
    if !s:CheckConfig()
        return
    endif

    let l:commonList = []
    let l:schemeList = s:OpenCatFile(a:cname)
    if empty(l:schemeList)
        return ''
    endif

    " We must remove the first item that is the category description.
    let l:commonList = l:schemeList[1:]

    if a:0 > 0
        for item in a:000
            let l:schemeList = s:OpenCatFile(item)
            if !empty(l:schemeList)
                let l:commonList = s:GetCommonItems(l:commonList, l:schemeList[1:])
                if empty(l:commonList)
                    break
                endif
            endif
        endfor
    endif

    if empty(l:commonList)
        call s:EchoMsg('warning', 'No common schemes found!')
        return ''
    else
        return join(l:commonList, '    ')
    endif
endfun " >>>
" s:RemoveScheme(...) <<<
" Remove a color scheme.
" @param ... Name of the color scheme to remove. If not passed the current
" color name will be used.
" @returns Nothing.
" ============================================================================
fun s:RemoveScheme(...)
    let l:sname = a:0 > 0 ? a:1 : exists('g:colors_name') ? g:colors_name : ''

    if strlen(l:sname) == 0
        call s:EchoMsg('error', "Color name not passed and 'g:colors_name' not set!")
        return
    endif

    let l:fileNames = globpath(&rtp, 'colors/'.l:sname.'.vim')
    if strlen(l:fileNames) == 0
        call s:EchoMsg('warning', 'Colorscheme "'.l:sname.'" not found!')
        return
    endif

    let l:fileList = split(l:fileNames, "\n")

    " Only the first one is used.
    if !s:Confirm('Are you sure to remove the scheme: "'.l:fileList[0].'"?')
        return
    endif

    " We must remove the scheme from any category.
    let l:listCategory = s:ListCategories('', '', '')

    for item in l:listCategory
        call s:RemoveFromCategory(item, l:sname)
    endfor

    call delete(l:fileList[0])
endfun " >>>
" s:FindScheme(...) <<<
" Finds a colorscheme installation directory.
" @param sname colorscheme name.
" @returns The path for the scheme or a string with 'not found' message.
fun s:FindScheme(...)
    let l:cname = exists('g:colors_name') ? g:colors_name : ''

    if a:0 > 0
        let l:cname = a:1
    endif

    if strlen(l:cname) == 0
        return "'colors_name' option is empty!"
    endif

    let l:fileNames = globpath(&rtp, 'colors/'.l:cname.'.vim')
    if strlen(l:fileNames) == 0
        return 'Colorscheme named "'.l:cname.'" not found!'
    endif
    return l:fileNames
endfun " >>>

"" Local Functions 
" s:EchoMsg(type, msg) <<<
" Echoes a message to the user
" @param type A string with the message type: 'error', 'warning', 'question'
" or 'none'.
" @param msg A string with the message to show.
" @returns Nothing.
" ============================================================================
fun s:EchoMsg(type, msg)
    if a:type ==? 'error'
        echohl ErrorMsg
    elseif a:type ==? 'warning'
        echohl WarningMsg
    elseif a:type ==? 'question'
        echohl Question
    endif
    echo a:msg
    echohl None
endfun " >>>
" s:Confirm(msg) <<<
" Request a confirmation to the user.
" @param msg Text of the confirmation.
" @returns TRUE if the user answer was 'yes'. Otherwise FALSE.
" ============================================================================
fun s:Confirm(msg)
    echohl Question
    let answer = input(a:msg.' ("yes" or "n") ')
    echohl None
    return answer == 'yes'
endfun " >>>
" s:CheckConfig() <<<
" Check the configuration of the storage folder.
" @returns 1 if the configuration is valid. Otherwise 0.
" ============================================================================
fun s:CheckConfig()
    if strlen(s:storage_folder) == 0
        call s:EchoMsg('error', 'No storage folder was defined. Type "help cscatalog-config"')
        return 0
    endif

    " Create the directory if it doesn't exists.
    if !isdirectory(s:storage_folder)
        call mkdir(s:storage_folder)
    endif
    return 1
endfun " >>>
" s:CatalogList() <<<
" Returns the list of categories.
" @returns A list with the catalog or an empty list.
" ============================================================================
fun s:CatalogList()
    if !s:CheckConfig()
        return []
    endif

    let l:categoryNames = globpath(s:storage_folder, '*')
    if strlen(l:categoryNames) == 0
        return []
    endif

    " The result of globpath() is a list of new-line separated paths.
    return split(l:categoryNames, "\n")
endfun " >>>
" s:OpenCatFile(fName) <<<
" Opens a file and returns it.
" @returns A list with the file contents or an empty list.
" ============================================================================
fun s:OpenCatFile(fName)
    let l:fileNames = globpath(s:storage_folder, a:fName)
    if strlen(l:fileNames) == 0
        return []
    endif

    " The result of globpath() is a list of new-line separated paths. We will
    " use only the first one.
    let l:fileList = split(l:fileNames, "\n")
    let l:fileName = l:fileList[0]

    if filereadable(l:fileName)
        try
            return readfile(l:fileName)
        catch
            return []
        endtry
    endif
endfun " >>>
" s:WriteCatFile(cname, content) <<<
" Writes a category file.
" @param cname The category name.
" @param content Content to write to file.
" @returns Nothing
" ============================================================================
fun s:WriteCatFile(cname, content)
    let l:filePath = s:storage_folder.'/'.a:cname
    call writefile(a:content, l:filePath)
endfun " >>>
" s:GetCommonItems(list1, list2) <<<
" Gets the itens that are common to both lists.
" @param list1 A first list.
" @param list2 A second list.
" @returns A list with only itens that are common to both lists.
" ============================================================================
fun s:GetCommonItems(list1, list2)
    let l:result = []

    for item1 in a:list1
        for item2 in a:list2
            if item1 == item2
                call add(l:result, item1)
                break
            endif
        endfor
    endfor

    return l:result
endfun " >>>

"" Commands
command -nargs=+ -complete=customlist,s:ListCategories CSAdd :call s:AddToCategory(<f-args>)
command -nargs=1 -complete=customlist,s:ListCategories CSRem :call s:RemoveFromCategory(<f-args>)
command -nargs=1 -complete=customlist,s:ListCategories CSDel :call s:RemoveCategory(<f-args>)
command -nargs=+ -complete=customlist,s:ListCategories CSList :echo s:ListSchemes(<f-args>)
command -nargs=? -complete=color CSCat :echo s:ListCategoriesFor(<f-args>)
command -nargs=? -complete=color CSFind :echo s:FindScheme(<f-args>)
command -nargs=? -complete=color CSRemoveScheme :call s:RemoveScheme(<f-args>)

" vim:ff=unix:fdm=marker:fmr=<<<,>>>
