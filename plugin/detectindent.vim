" Name:          detectindent (global plugin)
" Version:       1.0
" Author:        Ciaran McCreesh <ciaran.mccreesh at googlemail.com>
" Updates:       http://github.com/ciaranm/detectindent
" Purpose:       Detect file indent settings
"
" License:       You may redistribute this plugin under the same terms as Vim
"                itself.
"
" Usage:         :DetectIndent
"
"                " to prefer expandtab to noexpandtab when detection is
"                " impossible:
"                :let g:detectindent_preferred_expandtab = 1
"
"                " to set a preferred indent level when detection is
"                " impossible:
"                :let g:detectindent_preferred_indent = 4
"
"                " To use preferred values instead of guessing:
"                :let g:detectindent_preferred_when_mixed = 1
"
" Requirements:  Untested on Vim versions below 6.2

if exists("loaded_detectindent")
    finish
endif
let loaded_detectindent = 1
let g:detectindent_verbose_msg = 'Run :DetectIndent first'

if !exists('g:detectindent_preferred_expandtab')
    let g:detectindent_preferred_expandtab = &et
endif

if !exists('g:detectindent_preferred_indent')
    let g:detectindent_preferred_indent = &ts
endif

" magic mode is on
fun! <SID>IsCommentStart(line)
    return a:line =~ '/\*'
endfun

fun! <SID>IsCommentEnd(line)
    return a:line =~ '\*/'
endfun

fun! <SID>IsCommentLine(line)
    return a:line =~ '\s*\(//\|#\|"\)'
endfun

fun! <SID>IsTripleQuote(line)
    if &ft != "python"
        return 0
    endif

    if a:line =~ "\s*'''"
        return 1
    elseif a:line =~ '\s*"""'
        return 1
    endif

    return 0
endfun

fun! s:GetValue(option)
    if exists('b:'. a:option)
        return get(b:, a:option)
    else
        return get(g:, a:option)
    endif
endfun

fun! <SID>DetectIndent()
    let l:has_leading_tabs            = 0
    let l:has_leading_spaces          = 0
    let l:shortest_leading_spaces_run = 0
    let l:shortest_leading_spaces_idx = 0
    let l:max_lines                   = 128
    if exists("g:detectindent_max_lines_to_analyse")
        let l:max_lines = g:detectindent_max_lines_to_analyse
    endif

    let verbose_msg = ''
    let l:idx_end = line("$")
    let l:idx = 1
    while l:idx <= l:idx_end
        let l:line = getline(l:idx)

        " try to skip over comment blocks, they can give really screwy indent
        " settings in c/c++ files especially
        if <SID>IsCommentStart(l:line)
            while l:idx <= l:idx_end && ! <SID>IsCommentEnd(l:line)
                let l:idx = l:idx + 1
                let l:line = getline(l:idx)
            endwhile
            let l:idx = l:idx + 1
            continue
        endif

        " Skip comment lines since they are not dependable.
        if <SID>IsCommentLine(l:line)
            let l:idx = l:idx + 1
            continue
        endif

        " Skip python triple quote
        if <SID>IsTripleQuote(l:line)
            while l:idx <= l:idx_end
                let l:idx = l:idx + 1
                let l:line = getline(l:idx)
                if <SID>IsTripleQuote(l:line)
                    break
                endif
            endwhile
            let l:idx = l:idx + 1
            continue
        endif

        " Skip lines that are solely whitespace, since they're less likely to
        " be properly constructed.
        if l:line !~ '\S'
            let l:idx = l:idx + 1
            continue
        endif

        let l:leading_char = strpart(l:line, 0, 1)

        if l:leading_char == "\t"
            let l:has_leading_tabs = 1

        elseif l:leading_char == " "
            " only interested if we don't have a run of spaces followed by a
            " tab.
            if -1 == match(l:line, '^ \+\t')
                let l:has_leading_spaces = 1
                let l:spaces = strlen(matchstr(l:line, '^ \+'))
                if l:shortest_leading_spaces_run == 0 ||
                            \ l:spaces < l:shortest_leading_spaces_run
                    let l:shortest_leading_spaces_run = l:spaces
                    let l:shortest_leading_spaces_idx = l:idx
                endif
            endif

        endif

        let l:idx = l:idx + 1

        let l:max_lines = l:max_lines - 1

        if l:max_lines == 0
            let l:idx = l:idx_end + 1
        endif

    endwhile

    if l:has_leading_tabs && ! l:has_leading_spaces
        " tabs only, no spaces
        let l:verbose_msg = "Detected tabs only and no spaces"
        setl noexpandtab
        if s:GetValue("detectindent_preferred_indent")
            let &l:shiftwidth  = g:detectindent_preferred_indent
            let &l:tabstop     = g:detectindent_preferred_indent
        endif

    elseif l:has_leading_spaces && ! l:has_leading_tabs
        " spaces only, no tabs
        let l:verbose_msg = "Detected spaces only and no tabs"
        setl expandtab
        let &l:shiftwidth = l:shortest_leading_spaces_run
        let &l:tabstop    = l:shortest_leading_spaces_run

    elseif l:has_leading_spaces && l:has_leading_tabs && ! s:GetValue("detectindent_preferred_when_mixed")
        " spaces and tabs
        let l:verbose_msg = "Detected spaces and tabs"
        setl noexpandtab
        let &l:shiftwidth = l:shortest_leading_spaces_run
        let &l:tabstop    = l:shortest_leading_spaces_run

    else
        " no spaces, no tabs
        let l:verbose_msg = s:GetValue("detectindent_preferred_when_mixed") ? "preferred_when_mixed is active" : "Detected no spaces and no tabs"
        if s:GetValue("detectindent_preferred_expandtab")
            setl expandtab
        else
            setl noexpandtab
        endif
        let &l:shiftwidth  = g:detectindent_preferred_indent
        let &l:tabstop     = g:detectindent_preferred_indent

    endif

    let g:detectindent_verbose_msg = l:verbose_msg
                \ ."; has_leading_tabs: ".string(l:has_leading_tabs)
                \ .", has_leading_spaces: ".string(l:has_leading_spaces)
                \ .", shortest_leading_spaces_run: ".string(l:shortest_leading_spaces_run)
                \ .", shortest_leading_spaces_idx: ".string(l:shortest_leading_spaces_idx)
endfun

fun! <SID>DetectIndentV()
    echo g:detectindent_verbose_msg
endfun

fun! <SID>DetectIndentM(...)
    if a:0 == 0
        let l:et = g:detectindent_preferred_expandtab
        let l:ts = g:detectindent_preferred_indent
        let l:sw = l:ts
    elseif a:0 == 1
        let l:et = a:1
        let l:ts = g:detectindent_preferred_indent
        let l:sw = l:ts
    elseif a:0 == 2
        let l:et = a:1
        let l:ts = a:2
        let l:sw = l:ts
    else
        let l:et = a:1
        let l:ts = a:2
        let l:sw = a:3
    endif

    if l:et
        setl expandtab
    else
        setl noexpandtab
    endif

    let &l:tabstop     = l:ts
    let &l:shiftwidth  = l:sw
endfun

command! -bar -nargs=0 DetectIndent call <SID>DetectIndent()
command! -bar -nargs=0 DetectIndentV call <SID>DetectIndentV()
command! -bar -nargs=* DetectIndentM call <SID>DetectIndentM(<f-args>)

