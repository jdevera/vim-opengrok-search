" OpenGrokSearch: A plugin to search buffer contents in OpenGrok
" Mantainer: Jacobo de Vera <devel@jacobodevera.com>
" License: This plugin is distribuited under the Vim License

" TODO search in a specific path only
" TODO A command to set the search path


if exists("g:loaded_opengrok_search")
  finish
endif
let g:loaded_opengrok_search = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:ogs_browser_command')
    let g:ogs_browser_command = 'firefox'
endif

if !exists('b:ogs_app_url')
    let b:ogs_app_url = exists('g:ogs_app_url') ? g:ogs_app_url : ''
endif

if !exists('b:ogs_project')
    let b:ogs_project = exists('g:ogs_project') ? g:ogs_project : ''
endif

if !exists('g:ogs_create_maps')
    let g:ogs_create_maps = 1
endif


let s:qmap = { 'full' : 'q',
            \  'defs' : 'defs',
            \  'refs' : 'refs',
            \  'path' : 'path',
            \  'hist' : 'hist',}

function! s:echo(msg)
    redraw
    echomsg 'OpenGrokSearch: ' . a:msg
endfunction


" Got this function from vim's mail list, but it moves the cursor and it
" reselect text if it was not selected. There are some alternatives listed
" here: http://stackoverflow.com/q/1533565/116957
function! s:getVisualSelection() range
    let reg_save = getreg('"')
    let regtype_save = getregtype('"')
    let cb_save = &clipboard
    set clipboard&
    silent normal! ""gvy
    let selection = getreg('"')
    call setreg('"', reg_save, regtype_save)
    let &clipboard = cb_save
    return selection
endfunction


function! s:getUrl(query_type, name, project)
    if (!exists('b:ogs_app_url') || empty(b:ogs_app_url)) && ((!exists('g:ogs_app_url') || empty(g:ogs_app_url)))
        throw 'OpenGrokSearch:AppUrlNotSet'
    endif
    let app_url = (exists('b:ogs_app_url') && !empty(b:ogs_app_url)) ? b:ogs_app_url : g:ogs_app_url
    let url = app_url . '/search?' . a:query_type . '=' . a:name
    if a:project != ''
        let url .= '&project=' . a:project
    endif
    return url
endfunction


function! s:search(querytype, name)
    let ogsquery=get(s:qmap, a:querytype, '')
    if empty(ogsquery)
        call s:echo('Unknown query type: ' . a:querytype)
        return
    endif
    try
        let url=s:getUrl(ogsquery, a:name, b:ogs_project)
    catch /^OpenGrokSearch:AppUrlNotSet$/
        call s:echo('The g:ogs_app_url or b:ogs_app_url variables must be set')
        return
    endtry
    let command='silent !' . g:ogs_browser_command . ' "' . url . '"'
    exec command
    redraw!
endfunction


function! s:completeOptions(ArgLead, CmdLine, CursorPos)
    let commands = keys(s:qmap)
    let pattern = '\vOgv?\s*(' . join(commands, "|") . ')\s+$'
    if a:CmdLine =~ pattern
        return "\t"
    else
        let compl = join(commands, " \n") . " "
        return compl
    endif
endfunction


if !exists(':Og')
    command -buffer        -nargs=+ -complete=custom,s:completeOptions Og  call s:search(<f-args>)
endif
if !exists(':Ogv')
    command -buffer -range -nargs=1 -complete=custom,s:completeOptions Ogv call s:search(<f-args>, s:getVisualSelection())
endif
if !exists(':OgSetProject')
    command -buffer -nargs=1 OgSetProject let b:ogs_project = <q-args>
endif

function! s:map_once(map_command, lhs, rhs)
    if !hasmapto(a:rhs)
        let cmd = a:map_command . ' ' . a:lhs . ' ' . a:rhs
        exec cmd
    endif
endf

nnoremap <unique> <script> <Plug>OpenGrokSearchFull         <SID>Full
nnoremap <unique> <script> <Plug>OpenGrokSearchDefs         <SID>Defs
nnoremap <unique> <script> <Plug>OpenGrokSearchRefs         <SID>Refs
nnoremap <unique> <script> <Plug>OpenGrokSearchPath         <SID>Path
nnoremap <unique> <script> <Plug>OpenGrokSearchHist         <SID>Hist

vnoremap <unique> <script> <Plug>OpenGrokSearchSelectedFull <SID>FullV
vnoremap <unique> <script> <Plug>OpenGrokSearchSelectedDefs <SID>DefsV
vnoremap <unique> <script> <Plug>OpenGrokSearchSelectedRefs <SID>RefsV
vnoremap <unique> <script> <Plug>OpenGrokSearchSelectedPath <SID>PathV
vnoremap <unique> <script> <Plug>OpenGrokSearchSelectedHist <SID>HistV

nnoremap <SID>Full  :call <SID>search("full", expand("<cword>"))<CR>
nnoremap <SID>Defs  :call <SID>search("defs", expand("<cword>"))<CR>
nnoremap <SID>Refs  :call <SID>search("refs", expand("<cword>"))<CR>
nnoremap <SID>Path  :call <SID>search("path", expand("<cword>"))<CR>
nnoremap <SID>Hist  :call <SID>search("hist", expand("<cword>"))<CR>

vnoremap <SID>FullV :call <SID>search("full", <SID>getVisualSelection())<CR>
vnoremap <SID>DefsV :call <SID>search("defs", <SID>getVisualSelection())<CR>
vnoremap <SID>RefsV :call <SID>search("refs", <SID>getVisualSelection())<CR>
vnoremap <SID>PathV :call <SID>search("path", <SID>getVisualSelection())<CR>
vnoremap <SID>HistV :call <SID>search("hist", <SID>getVisualSelection())<CR>

if g:ogs_create_maps == 1
    command! -buffer -nargs=+ Nmaponce call <SID>map_once('nmap', <f-args>)
    command! -buffer -nargs=+ Vmaponce call <SID>map_once('vmap', <f-args>)

    Nmaponce <Leader>ogf <Plug>OpenGrokSearchFull
    Nmaponce <Leader>ogd <Plug>OpenGrokSearchDefs
    Nmaponce <Leader>ogr <Plug>OpenGrokSearchRefs
    Nmaponce <Leader>ogp <Plug>OpenGrokSearchPath
    Nmaponce <Leader>ogh <Plug>OpenGrokSearchHist

    Vmaponce <Leader>ogf <Plug>OpenGrokSearchSelectedFull
    Vmaponce <Leader>ogd <Plug>OpenGrokSearchSelectedDefs
    Vmaponce <Leader>ogr <Plug>OpenGrokSearchSelectedRefs
    Vmaponce <Leader>ogp <Plug>OpenGrokSearchSelectedPath
    Vmaponce <Leader>ogh <Plug>OpenGrokSearchSelectedHist

    delcommand Nmaponce
    delcommand Vmaponce
endif

let &cpo = s:save_cpo


