" emotions.vim - Rapid access to everywhere on the screen
" Author: Kevin Johnson <vadskye@gmail.com>

" if vi compatible mode is set, don't load
if &cp || exists("g:loaded_emotions")
    finish
endif
let g:loaded_emotions = 1

" Set a variable's default value, but don't override any existing value
" This allows user settings in the vimrc to work
function! s:init_variable(variable_name, value)
    if !exists('g:emotions_' . a:variable_name)
        if type(a:value) == type("")
            execute 'let g:emotions_' . a:variable_name . ' = "' . a:value . '"'
        elseif type(a:value) == type(0)
                \ || type(a:value) == type([])
                \ || type(a:value) == type({})
            execute 'let g:emotions_' . a:variable_name . ' = '. string(a:value)
        else
            echoerr "Unable to recognize type '" . type(a:value) .
                \ "' of '" . string(a:value) .
                \ "' for variable '" . a:variable_name . "'"
        endif
    endif
endfunction

function! s:set_default_options()
    let options = {
        \ 'create_commands': 1,
        \ 'create_find_mappings': 1,
        \ 'create_ijkl_mappings': 0,
        \ 'create_word_mappings': 1,
        \ 'enable_shading': 0,
        \ 'find_mapping_prefix': '<Leader>',
        \ 'force_uppercase': 1,
        \ 'highlight_type': has('conceal') && v:version>=704 ? 'conceal' : 'primary',
        \ 'ijkl_mapping_prefix': '<Leader>',
        \ 'match_separation_distance': 2,
        \ 'max_targets': 0,
        \ 'keys': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        \ 'replace_full_match': 0,
        \ 'shade_highlight_group': 'Comment',
        \ 'skip_folded_lines': 1,
        \ 'highlight_primary': 'IncSearch',
        \ 'highlight_secondary': 'Search',
        \ 'word_mapping_prefix': '<Leader>',
    \ }

    for variable_name in keys(options)
        call s:init_variable(variable_name, options[variable_name])
    endfor
endfunction
call s:set_default_options()

" Make sure that all options which should be set by the user have valid values
function! s:validate_options()
    let valid_values = {
        \ 'highlight_type': ['conceal', 'primary', 'alternating', 'sublabels'],
    \ }

    for [variable_name, values] in items(valid_values)
        let variable_value = get(g:, 'emotions_' . variable_name)
        if index(values, variable_value) == -1
            echohl WarningMsg
            echomsg "emotions: Variable g:emotions_" . variable_name . " has invalid value '" . variable_value . "'"
            echohl none
        endif
    endfor
endfunction
call s:validate_options()

" if we're forcing uppercase, make sure the keys are uppercase
if g:emotions_force_uppercase
    let g:emotions_keys = toupper(g:emotions_keys)
endif

" if we're using conceal, we need to set the 'Conceal' highlight group
" since there's no way to conceal with other highlight groups
if g:emotions_highlight_type == 'conceal'
    execute "highlight! link Conceal " . g:emotions_highlight_primary
endif

" reset options
" let s:old_cpo = &cpo
" set cpo&vim

"let g:emotions_grouping           = get(g: , 'emotions_grouping'           , 1)
"let g:emotions_enter_jump_first   = get(g: , 'emotions_enter_jump_first'   , 0)
"let g:emotions_space_jump_first   = get(g: , 'emotions_space_jump_first'   , 0)
"let g:emotions_inc_highlight      = get(g: , 'emotions_inc_highlight'      , 1)
"let g:emotions_move_highlight     = get(g: , 'emotions_move_highlight'     , 1)
"let g:emotions_landing_highlight  = get(g: , 'emotions_landing_highlight'  , 0)
"let g:emotions_cursor_highlight   = get(g: , 'emotions_cursor_highlight'   , 1)
"let g:emotions_use_regexp         = get(g: , 'emotions_use_regexp'         , 1)
"let g:emotions_add_search_history = get(g: , 'emotions_add_search_history' , 1)
"let g:emotions_off_screen_search  = get(g: , 'emotions_off_screen_search'  , 1)
"let g:emotions_force_csapprox     = get(g: , 'emotions_force_csapprox'     , 0)

" Mappings:

" <Plug> Mappings:

" Most <Plug> mappings should correspond to a standard vim key mapping
" This allows concise representation of the complexities of each command
" The standard format is '<Plug>(emotions-f)' for the 'f' mapping
" Modified versions of the functions, such as fullscreen versions, have suffixes
" So '<Plug>(emotions-f-full)' is like 'f', but for the whole screen

function! s:create_plug_mapping(name, function_name, function_args)
    silent execute 'nnoremap <silent> <Plug>(emotions-' . a:name . ') ' .
        \ ':<C-U>call emotions#' . a:function_name . '(' . string(a:function_args) . ')<CR>'
    " to allow proper inclusive/exclusive handling, force the current
    " operator to be handled internally via v:operator
    silent execute 'onoremap <silent> <Plug>(emotions-' . a:name . ') ' .
        \ '<Esc>:<C-U>call emotions#' . a:function_name . '(' . string(a:function_args) . ', v:operator)<CR>'
    " TODO: add xnoremap?
endfunction

" escape the | because we pass this into an eval
let s:patterns = {
    \ 'word_start': '\v((<\|>\|\s)@<=\S\|^$)',
    \ 'WORD_start': '\v((^\|\s)@<=\S\|^$)',
    \ 'word_end':   '\v(\S(>\|<\|\s)@=\|^$)',
    \ 'WORD_end':   '\v(\S(\s\|$)\|^$)',
    \ 'text_start': '\v[a-zA-Z_0-9]@<![a-zA-Z_0-9]',
    \ 'text_end':   '\v[a-zA-Z_0-9][a-zA-Z_0-9]@!',
\ }

let s:mapping_info = {
    \ 'search_for_characters': {
        \ 'base_mappings': {
            \ 'f': { 'direction': 'forward',  'include_destination': 1},
            \ 'F': { 'direction': 'backward', 'include_destination': 1},
            \ 't': { 'direction': 'forward',  'include_destination': 0},
            \ 'T': { 'direction': 'backward', 'include_destination': 0},
        \ },
        \ 'default_args': {
            \ 'scope': 'direction',
            \ 'character_count': 1,
        \ },
        \ 'modifiers': {
            \ '2':      { 'character_count': 2},
            \ 'X':      { 'character_count': 0},
            \ 'full':   { 'scope': 'window'},
            \ 'line':   { 'scope': 'within_line'},
            \ '2-full': { 'character_count': 2, 'scope': 'window'},
            \ '2-line': { 'character_count': 2, 'scope': 'within_line'},
        \ },
    \ },
    \ 'search_for_column': {
        \ 'base_mappings': {
            \ 'j': { 'direction': 'forward'},
            \ 'k': { 'direction': 'backward'},
        \ },
        \ 'default_args': {
            \ 'character_count': 1,
            \ 'include_destination': 1,
            \ 'scope': 'direction',
            \ 'start_of_line': 0,
        \ },
        \ 'modifiers': {
            \ 'full':     { 'scope': 'window'},
            \ 'sol':      { 'start_of_line': 1},
            \ 'full-sol': { 'scope': 'window', 'start_of_line': 1},
        \ },
    \ },
    \ 'search_for_last_search': {
        \ 'base_mappings': {
            \ 'n':          { 'direction': 'forward',  'include_destination': 0},
            \ 'N':          { 'direction': 'backward', 'include_destination': 1},
            \ 'n-relative': { 'direction': 'same',     'include_destination': 0},
            \ 'N-relative': { 'direction': 'reverse',  'include_destination': 0},
        \ },
        \ 'default_args': {
            \ 'scope': 'direction',
        \ },
        \ 'modifiers': {
            \ 'full':   { 'scope': 'window'},
            \ 'line':   { 'scope': 'within_line'},
        \ },
    \ },
    \ 'search_using_pattern': {
        \ 'base_mappings': {
            \ 'w':       { 'direction': 'forward',  'pattern': s:patterns.word_start, 'include_destination': 0},
            \ 'W':       { 'direction': 'forward',  'pattern': s:patterns.WORD_start, 'include_destination': 0},
            \ 'e':       { 'direction': 'forward',  'pattern': s:patterns.word_end,   'include_destination': 1},
            \ 'E':       { 'direction': 'forward',  'pattern': s:patterns.WORD_end,   'include_destination': 1},
            \ 'b':       { 'direction': 'backward', 'pattern': s:patterns.word_start, 'include_destination': 1},
            \ 'B':       { 'direction': 'backward', 'pattern': s:patterns.WORD_start, 'include_destination': 1},
            \ 'ge':      { 'direction': 'backward', 'pattern': s:patterns.word_end,   'include_destination': 0},
            \ 'gE':      { 'direction': 'backward', 'pattern': s:patterns.WORD_end,   'include_destination': 0},
            \ 'w-text':  { 'direction': 'forward',  'pattern': s:patterns.text_start, 'include_destination': 0},
            \ 'e-text':  { 'direction': 'forward',  'pattern': s:patterns.text_end,   'include_destination': 1},
            \ 'b-text':  { 'direction': 'backward', 'pattern': s:patterns.text_start, 'include_destination': 1},
            \ 'ge-text': { 'direction': 'backward', 'pattern': s:patterns.text_end,   'include_destination': 0},
        \ },
        \ 'default_args': {
            \ 'match_length': 1,
            \ 'scope': 'direction',
        \ },
        \ 'modifiers': {
            \ 'full': {'scope': 'window'},
            \ 'line': {'scope': 'within_line'},
        \ },
    \ },
\ }

for [function_name, function_properties] in items(s:mapping_info)
    for [map_name, map_args] in items(function_properties.base_mappings)
        let function_args = extend(copy(map_args), function_properties.default_args, 'error')
        call s:create_plug_mapping(map_name, function_name, function_args)
        for [modifier_label, modifier_args] in items(function_properties.modifiers)
            let modified_map_name = map_name . '-' . modifier_label
            let modified_function_args = extend(copy(function_args), modifier_args, 'force')
            call s:create_plug_mapping(modified_map_name, function_name, modified_function_args)
        endfor
    endfor
endfor

call s:create_plug_mapping('repeat', 'repeat', {})

" Key Mappings:

function! s:create_default_mapping(prefix, map_key, plug_mapping)
    execute "map " . a:prefix . a:map_key
        \ . ' <Plug>(emotions-' . a:plug_mapping . ')'
endfunction

if g:emotions_create_find_mappings
    for [map_key, plug_mapping] in items({
        \ 'f': 'f',
        \ 'F': 'F',
        \ 't': 't',
        \ 'T': 'T',
    \ })
        call s:create_default_mapping(g:emotions_find_mapping_prefix, map_key, plug_mapping)
    endfor
endif

if g:emotions_create_word_mappings
    for [map_key, plug_mapping] in items({
        \ 'b': 'b',
        \ 'B': 'B',
        \ 'w': 'w',
        \ 'W': 'W',
        \ 'e': 'e',
        \ 'E': 'E',
        \ 'ge': 'ge',
        \ 'gE': 'gE',
    \ })
        call s:create_default_mapping(g:emotions_word_mapping_prefix, map_key, plug_mapping)
    endfor
endif

if g:emotions_create_ijkl_mappings
    for [map_key, plug_mapping] in items({
        \ 'i': 'k',
        \ 'I': 'K',
        \ 'k': 'j',
        \ 'K': 'J',
        \ 'j': 'B',
        \ 'J': 'gE',
        \ 'l': 'W',
        \ 'L': 'E',
        \ 'u': 'b-text',
        \ 'U': 'ge-text',
        \ 'o': 'w-text',
        \ 'O': 'e-text',
    \ })
        call s:create_default_mapping(g:emotions_ijkl_mapping_prefix, map_key, plug_mapping)
    endfor
endif

if g:emotions_create_commands
    " Parameters:
    "   Required:
    "       "pattern" (string): the pattern to search for
    "   Optional:
    "       "direction" (string): either 'forward' or 'backward'
    "           If not provided, assume 'forward'
    "       "include_destination" (number): if true, include the destination
    "           for the purpose of operators
    "       "scope" (string): where to search for the match
    "           Must be 'direction', 'window', or 'within_line'
    "           If not provided, assume 'direction'
    command! -nargs=* FindPattern call emotions#search_using_pattern({
        \ 'pattern': [<f-args>][0],
        \ 'direction': get([<f-args>], 1, 'forward'),
        \ 'include_destination': get([<f-args>], 2, 1),
        \ 'scope': get([<f-args>], 3, 'direction'),
    \ })

    " Parameters:
    "   Optional:
    "       "character_count" (number): the number of characters to search for
    "           If not provided, assume 1
    "       "direction" (string): either 'forward' or 'backward'
    "           If not provided, assume 'forward'
    "       "include_destination" (number): if true, include the destination
    "           for the purpose of operators
    "       "scope" (string): where to search for the match
    "           Must be 'direction', 'window', or 'within_line'
    "           If not provided, assume 'direction'
    command! -nargs=* FindCharacters call emotions#search_for_characters({
        \ 'character_count': get([<f-args>], 0, 1),
        \ 'direction': get([<f-args>], 1, 'forward'),
        \ 'include_destination': get([<f-args>], 2, 1),
        \ 'scope': get([<f-args>], 3, 'direction'),
    \ })
endif
