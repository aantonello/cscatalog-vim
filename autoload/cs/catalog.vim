" Vim autload file
" Description: Simple Colorscheme Catalog builder.
" Version: 1.0
" Maintainer: Alessandro Antonello <antonello dot ale at gmail dot com>
" Last Change: 2013-01-02
" License: This script is in public domain.
" ============================================================================

"" Exported Functions 
" cs#catalog#listCategories(ArgLead, CmdLine, CursorPos) <<<
" List the current categories.
" @returns List of the current categories.
" ============================================================================
fun cs#catalog#listCategories(ArgLead, CmdLine, CursorPos)
    let storePath = s:CheckConfig()
    if strlen(storePath) == 0
        return []
    endif

    let l:categoryList = s:CatalogList(storePath)

    " We need only the category names. Not paths.
    call map(l:categoryList, 'fnamemodify(v:val, ":t")')

    " filtering the arg-lead, if needed
    if strlen(a:ArgLead) > 0
        call filter(l:categoryList, 'v:val =~? "^'.a:ArgLead.'"')
    endif
    call sort(l:categoryList)

    return l:categoryList

endfun " >>>
" cs#catalog#addScheme(...) <<<
" Add the current colorscheme to a category.
" @param ... A list of category names to add the current scheme.
" @returns Nothing.
" ============================================================================
fun cs#catalog#addScheme(...)
    let storePath = s:CheckConfig()
    if strlen(storePath) == 0
        return
    endif

    let l:scheme = exists('g:colors_name') ? g:colors_name : ''
    if strlen(l:scheme) == 0
        call s:EchoMsg('error', 'g:colors_name option not set.')
        return
    endif

    let l:argList = copy(a:000)
    let l:argList = insert(l:argList, l:scheme)
    let l:argList = insert(l:argList, storePath)

    call call(function('s:AddColorToCategories'), l:argList)

endfun " >>>
" cs#catalog#removeSchemeFromCategory(cname, ...) <<<
" Remove the current color scheme from a category.
" @param cname The category name.
" @returns Nothing.
" ============================================================================
fun cs#catalog#removeSchemeFromCategory(cname, ...)
    let storePath = s:CheckConfig()
    if strlen(storePath) == 0
        return
    endif

    let l:schemeList = s:ReadCatFile(storePath, a:cname)
    if empty(l:schemeList)
        " Nothint to do
        return
    endif

    if a:0 > 0
        let l:scheme = a:1
    elseif exists('g:colors_name')
        let l:scheme = g:colors_name
    else
        return
    endif

    " Filter the list
    call filter(l:schemeList, 'v:val !=? "'.l:scheme.'"')

    " Write the file again
    call s:WriteCatFile(storePath, a:cname, l:schemeList)
endfun " >>>
" cs#catalog#removeCategory(cname) <<<
" Removes a category from the catalog.
" @param cname Category name.
" @returns Nothing.
" ============================================================================
fun cs#catalog#removeCategory(cname)
    let storePath = s:CheckConfig()
    if strlen(storePath) == 0
        return
    endif

    let l:fileName = storePath.'/'.a:cname
    if !s:Confirm('Are you sure to remove the file: "'.l:fileName.'"?')
        return
    endif
    call delete(l:fileName)
endfun " >>>
" cs#catalog#listSchemes(cname, ...) <<<
" List all color schemes within a category.
" @param cname Category name
" @returns The list of color schemes in the category or an empty string.
" ============================================================================
fun cs#catalog#listSchemes(cname, ...)
    let storePath = s:CheckConfig()
    if strlen(storePath) == 0
        return
    endif

    let l:commonList = []
    let l:schemeList = s:ReadCatFile(storePath, a:cname)
    if empty(l:schemeList)
        return ''
    endif

    " We must remove the first item that is the category description.
    let l:commonList = l:schemeList[1:]

    if a:0 > 0
        for item in a:000
            let l:schemeList = s:ReadCatFile(storePath, item)
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
" cs#catalog#schemeCategories(...) <<<
" List the categories of a colorscheme.
" @param ... A colorscheme name, if not passed the current color will be used.
" @returns The list of categories where the colorscheme appears.
" ============================================================================
fun cs#catalog#schemeCategories(...)
    let storePath = s:CheckConfig()
    if strlen(storePath) == 0
        return ''
    endif

    let l:sname = ""
    let l:catalog = s:CatalogList(storePath)
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
        let l:schemes = s:ReadCatFile(storePath, category)
        if index(l:schemes, l:sname, 1, 1) >= 0
            call add(l:categories, category)
        endif
    endfor

    if empty(l:categories)
        return '"'.l:sname.'" not found in catalog'
    endif

    return join(l:categories, '    ')
endfun " >>>
" cs#catalog#findScheme(...) <<<
" Finds a colorscheme installation directory.
" @param sname colorscheme name.
" @returns The path for the scheme or a string with 'not found' message.
fun cs#catalog#findScheme(...)
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
" cs#catalog#removeScheme(...) <<<
" Remove a color scheme.
" @param ... Name of the color scheme to remove. If not passed the current
" color name will be used.
" @returns Nothing.
" ============================================================================
fun cs#catalog#removeScheme(...)
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
    let l:listCategory = cs#catalog#schemeCategories(l:sname)

    let l:listCategory = insert(l:listCategory, l:sname)
    let l:listCategory = insert(l:listCategory, storePath)
    call call(function('s:RemoveColorFromCategories'), l:listCategory)

    call delete(l:fileList[0])
endfun " >>>

" s:CathalogFunction(...) <<<
" Central command for list, add or remove colorschemes from categories.
" @param ... Many or nothing. When no parameter is passed the function will
" output the list of categories for the current colorscheme. When only one
" parameter is passed and no action is defined the function assumes that it is
" a colorscheme name and list the categories it pertains. For one or more
" arguments, the last argument must define what action to do. The current
" supported actions are:
" 'add:' Add the named colorscheme to the list of categories. Like ':CSAdd'.
" 'rem:' Remove the named colorscheme to the list of categories. Like
" ':CSRem'.
" 'del:' Deletes the colorscheme. Like ':CSRemoveScheme'.
" ============================================================================
fun s:CathalogFunction(...)

    if a:0 == 0
        return s:ListCategoriesFor()
    endif

    " Search for the action
    let l:addIndex = match(a:000, 'add:.*')
    let l:remIndex = match(a:000, 'rem:.*')
    let l:delIndex = match(a:000, 'del:.*')

    if l:addIndex < 0 && l:remIndex < 0 && l:delIndex < 0
        return call(function('s:ListCategoriesFor'), a:000)
    endif

    " Make a copy of the list so we can change it.
    let l:argList = copy(a:000)

    " Exec the action asked
    if l:addIndex >= 0
        let l:colorScheme = strpart(remove(l:argList, l:addIndex), strlen("add:"))
        call insert(l:argList, l:colorScheme)
        call call(function('s:AddColorToCategories'), l:argList)
    elseif l:remIndex >= 0
        let l:colorScheme = strpart(remove(l:argList, l:remIndex), strlen("rem:"))
        call insert(l:argList, l:colorScheme)
        call call(function('s:RemoveColorFromCategories'), l:argList)
    else
        let l:colorScheme = strpart(remove(l:argList, l:delIndex), strlen("del:"))
        call s:RemoveScheme(l:colorScheme)
    endif
endfun " >>>

" Local Functions
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
" @returns The directory of the categories or an empty string.
" ============================================================================
fun s:CheckConfig()
    let l:result = ''
    if exists('g:csc_StorageFolder')
        if strlen(g:csc_StorageFolder) > 0
            let l:result = expand(g:csc_StorageFolder)
        endif
    endif

    if strlen(l:result) == 0
        call s:EchoMsg('error', 'No storage folder was defined. Type "help cscatalog-config"')
        return ''
    endif

    " Create the directory if it doesn't exists.
    if !isdirectory(l:result)
        call mkdir(l:result, 'p')
    endif
    return l:result
endfun " >>>
" s:CatalogList(storagePath) <<<
" Returns the list of categories.
" @param storagePath The storage directory for categories.
" @returns A list with the catalog or an empty list.
" ============================================================================
fun s:CatalogList(storagePath)
    let l:categoryNames = globpath(a:storagePath, '*')
    if strlen(l:categoryNames) == 0
        return []
    endif

    " The result of globpath() is a list of new-line separated paths.
    return split(l:categoryNames, "\n")
endfun " >>>
" s:ColorsList() <<<
" Returns the list os colorschemes.
" ============================================================================
fun s:ColorsList()
    let l:colorsNames = globpath(&rtp, "colors/*.vim")
    if strlen(l:colorsNames) == 0
        return []
    endif

    " We break the result string into a list.
    let l:colorsList = split(l:colorsNames, "\n")

    " We can also remove the path information.
    call map(l:colorsList, 'fnamemodify(v:val, ":t")')

    return l:colorsList
endfun " >>>
" s:ReadCatFile(storePath, fName) <<<
" Opens a file and returns it.
" @param storePath Path where categories are stored.
" @param fName File to open and read.
" @returns A list with the file contents or an empty list.
" ============================================================================
fun s:ReadCatFile(storePath, fName)
    let l:fileList = globpath(a:storePath, a:fName, 0, 1)
    if len(l:fileList) == 0
        return []
    endif

    let l:fileName = l:fileList[0]

    if filereadable(l:fileName)
        try
            return readfile(l:fileName)
        catch
            return []
        endtry
    endif
endfun " >>>
" s:WriteCatFile(storePath, cname, content) <<<
" Writes a category file.
" @param storePath Path where categories are stored.
" @param cname The category name.
" @param content Content to write to file.
" @returns Nothing
" ============================================================================
fun s:WriteCatFile(storePath, cname, content)
    let l:filePath = a:storePath.'/'.a:cname
    call writefile(a:content, l:filePath)
endfun " >>>
" s:AddColorToCategories(storePath, a:color, ...) <<<
" Add a colorscheme to a list of categories.
" @param storePath Path where categories are stored.
" @param a:color Name of the color scheme to add.
" @param ... Comma separated list of categories to add the colorscheme.
" ============================================================================
fun s:AddColorToCategories(storePath, color, ...)
    for categoryName in a:000
        let l:categoryFile = s:ReadCatFile(a:storePath, categoryName)
        if empty(l:categoryFile)
            call add(l:categoryFile, '')        " First line reserved to a description.
            call add(l:categoryFile, a:color)
        else
            " Only if the color scheme is not in that file.
            if index(l:categoryFile, a:color) < 0
                call add(l:categoryFile, a:color)
            endif
        endif

        " Write the category file.
        call s:WriteCatFile(a:storePath, categoryName, l:categoryFile)
    endfor
endfun " >>>
" s:RemoveColorFromCategories(storePath, a:color, ...) <<<
" Removes a colorscheme from one or more categories.
" @param storePath Path where categories are stored.
" @param a:color The color scheme name.
" @param ... The list of categories to remove the colorscheme.
" ============================================================================
fun s:RemoveColorFromCategories(storePath, color, ...)
    for categoryName in a:000
        let l:categoryData = s:ReadCatFile(a:storePath, categoryName)
        if !empty(l:categoryData)
            "" Filter the list, removing the colorscheme from it.
            call filter(l:categoryData, 'v:val !=? "'.a:color.'"')
            "" Rewrite the file.
            call s:WriteCatFile(a:storePath, categoryName, l:categoryData)
        endif
    endfor
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

" vim:ff=unix:fdm=marker:fmr=<<<,>>>
