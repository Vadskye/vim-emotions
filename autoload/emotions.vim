" emotions.vim - Rapid access to everywhere on the screen
" Author: Kevin Johnson <vadskye@gmail.com>

if exists("g:loaded_emotions_autoload")
    finish
endif
let g:loaded_emotions_autoload = 1

" store information about the previous motion so we can repeat it
let s:last_motion_args = {}
let s:last_operator = ""

" display the given message to the user
" this is preferable to using echomsg because it makes highlighting easier
" Paramters:
"   Required:
"       "message" (string): message to display
"       "highlight_color" (string): highlight group for the message
"           Use 'None' to disable highlighting
function! s:display_message(message, highlight_color) abort
    execute "echohl " . a:highlight_color
    echomsg a:message
    echohl None
endfunction

if exists('*matchaddpos')
    function! s:matchaddpos(...)
        return call('matchaddpos', a:000)
    endfunction
else
    " reimplement matchaddpos for versions of vim without that function
    " properly representing matchaddpos is more complicated than this
    " but this plugin only uses one version of it
    function! s:matchaddpos(group, pos, ...) abort
        let patterns = []
        for location in a:pos
            call add(patterns, '\v%' . location[0] . 'l%' . location[1] . 'c'
                \ . '.{1,' . get(location, 2, 1) . '}'
            \ )
        endfor
        let pattern = '\v(' . join(patterns, '|') . ')'
        return call('matchadd', [a:group, pattern] + a:000)
    endfunction
endif

" Ask the user for characters to search for
" Construct a pattern using the provided characters
" Then search for it using #search_using_pattern
" Parameters:
"   Required:
"       "character_count" (number): number of characters to search for
"       "direction" (string): as in s:search_using_pattern
"       "include_destination" (number): as in s:search_using_pattern
"       "scope" (string): as in s:search_using_pattern
function! emotions#search_for_characters(args, ...) abort
    let character_count = a:args.character_count
    let current_operator = get(a:000, 0)

    if character_count == 0
        let character_count = 100
        let prompt_message = 'Search for any number of characters: '
    elseif character_count == 1
        let prompt_message = 'Search for ' . character_count . ' character: '
    else
        let prompt_message = 'Search for ' . character_count . ' characters: '
    endif

    let pattern = '\V'
    if g:emotions_force_uppercase
        let pattern = pattern . '\c'
    else
        let pattern = pattern . '\C'
    endif

    " we need to know how long the match should be
    let match_length = 0

    for i in range(character_count)
        call s:display_message(prompt_message, 'Question')
        let input_char = nr2char(getchar())
        if input_char == "\<Esc>"
            redraw
            call s:display_message("Cancelled", 'None')
            return
        elseif input_char == "\<CR>"
            if strlen(pattern)
                break
            else
                redraw
                call s:display_message("No pattern to complete", 'WarningMsg')
                return
            endif
        endif

        let pattern = pattern . input_char

        " if there are more characters to enter, highlight matches for the
        " characters entered so far
        if i < a:args.character_count - 1
            let search_match_id = matchadd('IncSearch', pattern)
            redraw
            call matchdelete(search_match_id)
        endif

        let match_length = match_length + 1
    endfor

    call emotions#search_using_pattern({
        \ 'direction': a:args.direction,
        \ 'include_destination': a:args.include_destination,
        \ 'match_length': match_length,
        \ 'pattern': pattern,
        \ 'scope': a:args.scope,
    \ }, current_operator)

endfunction

" public interface for s:search_using_pattern
" Parameters:
"   Required:
"       "direction" (string): as s:search_using_pattern
"       "include_destination" (number): as s:search_using_pattern
"       "match_length" (number): as s:search_using_pattern
"       "pattern" (string): as s:search_using_pattern
"       "scope" (string): as s:search_using_pattern
"   Optional:
"       "repeat" (number): if true, currently executing a repeated motion
function! emotions#search_using_pattern(args, ...) abort

    " determine whether we are currently executing an operator
    let current_operator = get(a:000, 0, "")
    if get(a:args, 'repeat')
        let current_operator = s:last_operator
    endif

    " save information about the current motion so we can repeat it
    let s:last_motion_args = a:args
    let s:last_operator = current_operator

    call s:search_using_pattern({
        \ 'current_operator': current_operator,
        \ 'direction': a:args.direction,
        \ 'force_uppercase': g:emotions_force_uppercase,
        \ 'highlight_colors': {
            \ 'primary': g:emotions_highlight_primary,
            \ 'secondary': g:emotions_highlight_secondary,
        \ },
        \ 'highlight_type': g:emotions_highlight_type,
        \ 'include_destination': a:args.include_destination,
        \ 'keys': g:emotions_keys,
        \ 'match_length': a:args.match_length,
        \ 'match_separation_distance': g:emotions_match_separation_distance,
        \ 'max_targets': g:emotions_max_targets,
        \ 'pattern': a:args.pattern,
        \ 'replace_full_match': g:emotions_replace_full_match,
        \ 'scope': a:args.scope,
        \ 'shade_highlight_group': g:emotions_enable_shading
            \ ? g:emotions_shade_highlight_group
            \ : "",
        \ 'skip_folded_lines': g:emotions_skip_folded_lines,
    \ })

    if exists('current_operator') && current_operator != ""
        silent! call repeat#set("\<Plug>(emotions-repeat)", v:count)
        if current_operator == 'c'
            startinsert
        endif
    endif
endfunction

" perform the full suite of operations - find match locations, prompt the user
" for which match they want, and navigate to the match
" Parameters:
"   Required:
"       "current_operator" (string): if non-empty, we are currently in
"           operator-pending mode trying to resolve this operator
"       "direction" (string): direction of search, needed to mark targets in order
"           Must be 'forward' or 'backward'
"       "force_uppercase" (number): if true, coerce input to be uppercase
"       "highlight_colors" (hash): highlight colors to use, organized by purpose
"       "highlight_type" (string): type of highlighting to use
"           Must be 'conceal', 'primary' or 'alternating'
"       "include_destination" (number): if true, include the destination
"           for the purposes of operators (delete, copy, etc.)
"       "keys" (string): string containing the keys used to mark target locations
"       "match_length" (number): how long matches found by the pattern should be
"           If 0, each match may have a variable length, which is slower
"       "match_separation_distance" (number): minimum distance between two close matches
"       "max_targets" (number): maximum number of targets to highlight
"       "pattern" (string): pattern to search for
"       "replace_full_match" (number): if true, replace the full match when
"           generating labels, rather than just the characters covered by the
"           labels
"       "scope" (string): where to search for the pattern
"           Must be 'direction', 'window', or 'within_line'
"       "shade_highlight_group" (string): if nonempty, shade everything except the
"           labels with this highlight group to make the labels easier to see
"       "skip_folded_lines" (number): if true, skip matches within folded lines
function! s:search_using_pattern(args) abort

    let original_buffer_settings = s:prepare_buffer({'highlight_type': a:args.highlight_type})
    let original_cursor_location = [line('.'), col('.')]

    try
        if a:args.scope == 'direction'
            if a:args.direction == 'forward'
                let window_boundaries = [line('.'), line('w$')]
            elseif a:args.direction == 'backward'
                let window_boundaries = [line('.'), line('w0')]
            else
                throw "Invalid direction: " . a:args.direction
            endif
        elseif a:args.scope == 'window'
            let window_boundaries = [line('w0'), line('w$')]
        elseif a:args.scope == 'within_line'
            let window_boundaries = [line('.'), line('.')]
        else
            throw "Invalid scope: " . a:args.scope
        endif

        let match_locations = s:find_match_locations({
            \ 'direction': a:args.direction,
            \ 'match_length': a:args.match_length,
            \ 'match_separation_distance': a:args.match_separation_distance,
            \ 'max_targets': a:args.max_targets,
            \ 'original_cursor_location': original_cursor_location,
            \ 'pattern': a:args.pattern,
            \ 'replace_full_match': a:args.replace_full_match,
            \ 'scope': a:args.scope,
            \ 'skip_folded_lines': a:args.skip_folded_lines,
            \ 'window_boundaries': window_boundaries,
        \ })

        if empty(match_locations)
            call s:display_message('No matches found', 'None')
        endif

        " go back to the starting location - if we succeeded, we want to be there
        " to jump correctly, and if not, we want to end there
        keepjumps call cursor(original_cursor_location)

        if a:args.highlight_type == 'conceal'
            " conceal also conceals incsearch targets
            " is this a Vim bug?
            nohlsearch
            " matching_info contains:
            "  match_ids (hash)
            "  labeled_locations (hash)
            let matching_info = s:conceal_match_locations({
                \ 'keys': a:args.keys,
                \ 'match_locations': match_locations,
                \ 'pattern': a:args.pattern,
                \ 'replace_full_match': a:args.replace_full_match,
            \ })
            let match_ids = matching_info.match_ids
            let labeled_locations = matching_info.labeled_locations
        else

            " non-conceal searching leaves a trail in the undo history
            " if we're not doing an operation, we don't want it in the history
            if empty(a:args.current_operator)
                silent! undojoin
            endif

            " matching_info contains:
            "  labeled_locations (hash)
            "  original_lines (hash)
            let matching_info = s:label_match_locations({
                \ 'keys': a:args.keys,
                \ 'match_locations': match_locations,
                \ 'replace_full_match': a:args.replace_full_match,
            \ })
            let labeled_locations = matching_info.labeled_locations
            let original_lines = matching_info.original_lines
            let match_ids = s:highlight_match_locations({
                \ 'highlight_colors': a:args.highlight_colors,
                \ 'highlight_type': a:args.highlight_type,
                \ 'labeled_locations': labeled_locations,
                \ 'pattern': a:args.pattern,
            \ })
        endif

        " shade everything which is not a label
        " use a lower priority to avoid overwriting the highlighting on the labels
        if ! empty(a:args.shade_highlight_group)
            throw "Shading should not be enabled"
            call add(match_ids, matchadd(
                \ a:args.shade_highlight_group,
                \ '.',
                \ 1,
            \ ))
        endif

        " bring the cursor back to the original location before redrawing
        " this makes visual mode mappings draw properly
        keepjumps call cursor(original_cursor_location)

        redraw
        " chosen_location is [line, col, match_length?] if successful
        " or 0 if failed
        " this function redraws immediately after prompting
        let chosen_location = s:prompt_for_labeled_location({
            \ 'force_uppercase': a:args.force_uppercase,
            \ 'labeled_locations': labeled_locations,
        \ })

    catch

        keepjumps call cursor(original_cursor_location)
        redraw!
        call s:display_message('Emotions: ' . v:exception . '    (' . v:throwpoint . ')', 'WarningMsg')

    finally

        " this looks like it should belong in a 'restore_buffer' function, but
        " that doesn't guarantee that it will run
        " to avoid accidentally leaving configuration changes / replaced text in
        " the user's buffer, this has to run, so leave it here

        " restore the text of the original lines
        if exists("original_lines")
            undojoin | call s:reset_original_lines(original_lines)
        endif

        " restore buffer settings
        for [setting_name, value] in items(original_buffer_settings)
            call setbufvar("", '&' . setting_name, value)
        endfor

        " remove highlights
        if exists("match_ids")
            for id in match_ids
                call matchdelete(id)
            endfor
        endif

        " stupid hackery
        if getbufvar("", "emotions_has_been_run") == 1
            syntax clear ThisGroupNameShouldNeverEverBeUsed
            call setbufvar("", "emotions_has_been_run", 2)
        endif
    endtry

    " finally, jump to the chosen location, including executing any pending
    " operators
    if exists("chosen_location") && type(chosen_location) == type([])
        call s:jump_to_location({
            \ 'current_operator': a:args.current_operator,
            \ 'direction': a:args.direction,
            \ 'include_destination': a:args.include_destination,
            \ 'location': chosen_location
        \ })
        redraw
        call s:display_message("Emotions: Jumped to " . string(chosen_location), 'None')
    endif

    return 1
endfunction

function! s:reset_original_lines(original_lines) abort
    for [line_number, line_text] in items(a:original_lines)
        keepjumps call setline(line_number, line_text)
    endfor
endfunction

" Prepare the current buffer for emotions search/replacement
" Parameters:
"   Required:
"       "highlight_type" (string): as s:search_using_pattern
" Returns:
"   original_buffer_settings (hash): how the buffer was originally configured
function! s:prepare_buffer(args) abort
    let original_buffer_settings = {}
    let new_buffer_settings = {
        \ 'foldmethod':  'manual',
        \ 'scrolloff':   0,
        \ 'spell':       0,
        \ 'virtualedit': ""
    \ }

    if a:args.highlight_type == 'conceal'
        let new_buffer_settings['concealcursor'] = "n"
        let new_buffer_settings['conceallevel'] = 1

        " Vim has a strange bug where matchadd() does not properly update conceal
        " highlighting unless at least one syntax command has been run since the
        " buffer opened.
        " The group created by the command must have made an actual change to
        " the buffer, and it must persist until the first matchaddpos() has been
        " called.  (this was fun to debug)
        " To solve this, run a useless syntax command and then undo it later
        if ! getbufvar("", "emotions_has_been_run")
            syntax match ThisGroupNameShouldNeverEverBeUsed '\v^%1c%1l.'
            call setbufvar("", "emotions_has_been_run", 1)
        endif
    else
        let new_buffer_settings['modified'] = 0
        let new_buffer_settings['modifiable'] = 1
        let new_buffer_settings['readonly'] = 0
    endif

    for [setting_name, value] in items(new_buffer_settings)
        let original_buffer_settings[setting_name] = getbufvar("", '&' . setting_name)
        call setbufvar("", "&" . setting_name, value)
    endfor

    return original_buffer_settings
endfunction

" Find a list of locations which match the given pattern.
" This moves the cursor.
" Parameters:
"   Required:
"       "direction" (string): as s:search_using_pattern
"       "keys" (string): as s:search_using_pattern
"       "match_length" (number): as s:search_using_pattern
"       "match_separation_distance" (number): as s:search_using_pattern
"       "max_targets" (number): as s:search_using_pattern
"       "original_cursor_location" (list): as s:search_using_pattern
"       "pattern" (string): as s:search_using_pattern
"       "replace_full_match" (number): as s:replace_full_match
"           If true, store information about match length
"           If false, match length is irrelevant to future work, so skip that
"           processing for speed
"       "scope" (string): as s:search_using_pattern
"       "skip_folded_lines" (number): as s:search_using_pattern
"       "window_boundaries" (list): range to search within
"           Takes the format [first_line_number, last_line_number]
" Returns:
"   "match_locations" (list): list of locations matching the given pattern
"       Each location is a list of the form:
"       [line (number), col (number), match_length (number)]
function! s:find_match_locations(args) abort
    let match_separation_distance = a:args.match_separation_distance
    let max_targets = a:args.max_targets
    let first_line = a:args.window_boundaries[0]
    let last_line = a:args.window_boundaries[1]
    let match_locations = []
    let match_length = a:args.match_length

    if a:args.direction == 'backward'
        let search_flags = 'b'
    else
        let search_flags = ""
    endif

    let target_count = 0

    while 1
        " location = [line, col]
        let location = searchpos(a:args.pattern, search_flags, last_line)
        " if no match was found, stop searching
        if location == [0, 0]
            break
        endif

        if a:args.skip_folded_lines && foldclosed(location[0]) != -1
            " if we are in a fold, and should skip folds, go to the other side of the fold
            " and do not save this match location
            if a:args.direction == 'backward'
                keepjumps call cursor(foldclosed(location[0]), 1)
            else
                keepjumps call cursor(foldclosedend(location[0]), 1)
            endif
        else

            let match_length = 1
            " if we care about match length, determine the length of the match
            " and save that information in the location
            if a:args.replace_full_match
                " determine the length of the match - either a fixed given
                " length, or a variable length that must be checked
                if a:args.match_length
                    let match_length = a:args.match_length
                else
                    let match_end_location = searchpos(a:args.pattern, search_flags . "e", last_line)
                    let match_length = match_end_location[1] - location[1]
                endif

                " if we're going backwards, return to the start of the match
                " to avoid looping over the match indefinitely
                if a:args.direction == 'backward'
                    keepjumps call cursor(location)
                endif
            endif

            " add the match length to the location
            call add(location, match_length)
            " the location is now in the format [line, col, match_length]

            " as a special case, if the current match is at the end of the line,
            " note this in the location so we can handle this when adding labels
            " otherwise the label will try to extend beyond the end of the line
            " and things will get weird
            if location[1] >= col('$') - 1
                call add(location, 'eol')
            endif

            call add(match_locations, location)

            " push the cursor to avoid overlapping target labels
            if match_separation_distance
                if a:args.direction == 'backward'
                    keepjumps call cursor(
                        \ location[0],
                        \ max([1, location[1] - match_separation_distance])
                    \ )
                else
                    keepjumps call cursor(
                        \ location[0],
                        \ location[1] + match_separation_distance
                    \ )
                endif
            endif


            let target_count = target_count + 1
            " check if we should stop finding targets
            if max_targets > 0 && target_count >= max_targets
                break
            endif
        endif
    endwhile

    return match_locations
endfunction

" Conceal each match location, using the labels to hide the original text
" Parameters:
"   Required:
"       "keys" (string): string containing the keys used to mark target locations
"       "match_locations" (list): list of locations matching the given pattern
"           Each location is a list of the form [line (number), col (number)]
"       "pattern" (string): pattern being searched for
"       "replace_full_match" (number): as s:search_using_pattern
" Returns:
"   {
"       "match_ids": [id_number, ...],
"       "labeled_locations": {
"           <label>: [line, col],
"           ...
"       },
"   }
function! s:conceal_match_locations(args) abort
    let match_locations = a:args.match_locations
    " we need to know which key inputs should go to which locations
    " the keys are the labels for each location, and the values are the location
    let labeled_locations = {}
    let match_ids = []

    if len(match_locations) <= strlen(a:args.keys)
        " if there are enough keys to cover the locations, simply assign them
        " directly, matching the location index with the key index
        for i in range(len(match_locations))
            let location = match_locations[i]
            let key = a:args.keys[i]

            call add(match_ids, s:matchaddpos(
                \ 'Conceal',
                \ [location],
                \ 10,
                \ -1,
                \ {'conceal': key},
            \ ))

            let labeled_locations[key] = [location[0], location[1], 1]
        endfor
    else
        " TODO: use correct keys for two-key labels
        let first_key_index = 0
        let second_key_index = 0
        let key_count = len(a:args.keys)

        for location in match_locations
            if second_key_index >= key_count
                let first_key_index = first_key_index + 1
                let second_key_index = 0

                " safety valve if we have used every possible key combination
                " this should be very rare
                if first_key_index >= key_count
                    call s:display_message('Warning: every possible key combination used', 'WarningMsg')
                    break
                endif
            endif
            let first_key = a:args.keys[first_key_index]
            let second_key = a:args.keys[second_key_index]

            let line_number = location[0]
            let col_number = location[1]

            if a:args.replace_full_match
                let match_length = max([1, location[2] - 1])
            else
                let match_length = 1
            endif

            " if the location is at the end of the line, we can't just add the
            " second key as the next character
            if location[-1] ==# 'eol'
                " if it is also at the beginning of the line
                if col_number == 1
                    " witchcraft relying on undocumented behavior in vim's
                    " conceal implementation
                    " this causes unexpected visuals if one-character line
                    " with the match is preceded by a line that is so long
                    " that it wraps the screen
                    let match_length = 999
                    " TODO: make this work for non-conceal
                else
                    " just move the starting location back by a space
                    let col_number = col_number - 1
                endif
            endif

            " at this point, we have two keys we need to use to make label,
            " a line_number and col_number which should point to
            " the location of the first key,
            " and the match_length

            " create two conceals - one for the first key, and the other
            " for the second key
            " the first key always conceals one character
            call add(match_ids, s:matchaddpos(
                \ 'Conceal',
                \ [[line_number, col_number, 1]],
                \ 10,
                \ -1,
                \ {'conceal': first_key},
            \ ))
            " the second key is immediately after the first key
            " it conceals the rest of the match if replace_full_match is enabled
            " otherwise it also conceals a single character
            call add(match_ids, s:matchaddpos(
                \ 'Conceal',
                \ [[line_number, col_number + 1, match_length]],
                \ 20,
                \ -1,
                \ {'conceal': second_key},
            \ ))

            " it is important to use location here instead of
            " [line_number, col_number] because we may have changed col_number
            if ! has_key(labeled_locations, first_key)
                let labeled_locations[first_key] = {}
            endif
            let labeled_locations[first_key][second_key] = [location[0], location[1], 2]

            let second_key_index += 1
        endfor
    endif

    return {
        \ 'labeled_locations': labeled_locations,
        \ 'match_ids': match_ids,
    \ }
endfunction

" Highlight each match location to allow user input
" Parameters:
"   Required:
"       "keys" (string): as s:search_using_pattern
"       "match_locations" (list): list of locations matching the given pattern
"           Each location is a list of the form [line (number), col (number)]
"       "replace_full_match" (number): as s:search_using_pattern
" Returns:
"   {
"       "labeled_locations" (hash):
"       {
"           <label>: [line, col],
"           ...
"           <label>: {
"               <sublabel>: [line, col],
"               ...
"           },
"           ...
"       }
"       "original_lines": {
"           <line_number>: <line text before key substitution>,
"           ...
"       },
"   }
function s:label_match_locations(args) abort
    let match_locations = a:args.match_locations

    " we need to save the original lines, before substitution, to restore them
    " the keys are line numbers, and the values are the original line
    let original_lines = {}
    " we also need to know which key inputs should go to which locations
    " the keys are the labels for each location, and the values are the location
    let labeled_locations = {}

    if len(match_locations) <= strlen(a:args.keys)
        " if there are enough keys to cover the locations, simply assign them
        " directly, matching the location index with the key index
        for i in range(len(match_locations))
            let location = match_locations[i]
            let key = a:args.keys[i]
            let line_text = getline(location[0])

            " store the original line
            if ! has_key(original_lines, location[0])
                let original_lines[ location[0] ] = line_text
            endif

            if a:args.replace_full_match
                let match_length = max([1, location[2]])
            else
                let match_length = 1
            endif

            let replaced_line_text = substitute(
                \ line_text,
                \ '\v%' . location[1] . 'c.{0,' . match_length . '}',
                \ key,
                \ "",
            \ )
            keepjumps call setline(location[0], replaced_line_text)

            let labeled_locations[key] = [location[0], location[1]]
        endfor
    else
        " If there are too many locations, use two-key labels
        " TODO: use correct keys for two-key labels
        let first_key_index = 0
        let second_key_index = 0
        let key_count = len(a:args.keys)

        for location in match_locations
            if second_key_index >= key_count
                let first_key_index = first_key_index + 1
                let second_key_index = 0

                " safety valve if we have used every possible key combination
                " this should be very rare
                if first_key_index >= key_count
                    call s:display_message('Warning: every possible key combination used', 'WarningMsg')
                    break
                endif
            endif
            let first_key = a:args.keys[first_key_index]
            let second_key = a:args.keys[second_key_index]

            let line_number = location[0]
            let col_number = location[1]
            let line_text = getline(line_number)

            if a:args.replace_full_match
                " subtract 1 from the match length because there are two keys,
                " each of which takes up space
                let match_length = max([1, location[2] - 1])
            else
                let match_length = 1
            endif

            " non-conceal-specific code starts here

            " at this point, we have two keys we need to use to make a label,
            " a line_number and col_number which should point to
            " the location of the first key,
            " and the match_length

            " store the original line
            if ! has_key(original_lines, line_number)
                let original_lines[line_number] = line_text
            endif

            if col_number == 1
                let replaced_line_text = first_key . second_key . line_text[2:]
            elseif location[-1] ==# 'eol'
                let replaced_line_text = line_text[0: col_number-2] . first_key . second_key
            else
                let replaced_line_text = line_text[0: col_number-2] . first_key . second_key . line_text[col_number+match_length :]
            endif

            keepjumps call setline(line_number, replaced_line_text)

            if ! has_key(labeled_locations, first_key)
                let labeled_locations[first_key] = {}
            endif
            let labeled_locations[first_key][second_key] = [line_number, col_number]

            let second_key_index += 1
        endfor
    endif

    return {
        \ 'labeled_locations': labeled_locations,
        \ 'original_lines': original_lines,
    \ }
endfunction

" Highlight the current matches to make them easier to see
" Parameters:
"   Required:
"       "highlight_colors" (hash): as s:search_using_pattern
"       "highlight_type" (string): as s:search_using_pattern
"       "labeled_locations" (hash):
"       {
"           <label>: [line, col],
"           ...
"           <label>: {
"               <sublabel>: [line, col],
"               ...
"           },
"           ...
"       }
"       "pattern" (string): pattern being searched for
" Returns:
"   "match_ids" (list): list of IDs corresponding to match groups
function! s:highlight_match_locations(args) abort
    let match_ids = []
    let match_length = len(a:args.pattern)

    if a:args.highlight_type == 'primary'
        let current_color = a:args.highlight_colors.primary

        for [first_key, location] in items(a:args.labeled_locations)
            if type(location) == type([])
                call add(match_ids, s:matchaddpos(
                    \ current_color,
                    \ [[location[0], location[1], 1]],
                \ ))
            elseif type(location) == type({})
                for sublocation in values(location)
                    call add(match_ids, s:matchaddpos(
                        \ current_color,
                        \ [[sublocation[0], sublocation[1], 2]],
                    \ ))
                endfor
            endif
        endfor

    elseif a:args.highlight_type == 'alternating'
        let alternate_labels_colors = [a:args.highlight_colors.primary, a:args.highlight_colors.secondary]
        let current_color_index = 0
        let current_color = alternate_labels_colors[current_color_index]

        for [first_key, location] in items(a:args.labeled_locations)
            if type(location) == type([])
                call add(match_ids, s:matchaddpos(
                    \ current_color,
                    \ [[location[0], location[1], 1]],
                \ ))
                " toggle between the two colors
                let current_color_index = (current_color_index + 1) % 2
                let current_color = alternate_labels_colors[current_color_index]

            elseif type(location) == type({})
                for sublocation in values(location)
                    call add(match_ids, s:matchaddpos(
                        \ current_color,
                        \ [[sublocation[0], sublocation[1], 2]],
                    \ ))
                    " toggle between the two colors
                    let current_color_index = (current_color_index + 1) % 2
                    let current_color = alternate_labels_colors[current_color_index]
                endfor
            endif
        endfor

    elseif a:args.highlight_type == 'sublabels'
        for [first_key, location] in items(a:args.labeled_locations)
            if type(location) == type([])
                call add(match_ids, s:matchaddpos(
                    \ a:args.highlight_colors.primary,
                    \ [[location[0], location[1], 1]],
                \ ))
            elseif type(location) == type({})
                for sublocation in values(location)
                    call add(match_ids, s:matchaddpos(
                        \ a:args.highlight_colors.primary,
                        \ [[sublocation[0], sublocation[1], 1]],
                    \ ))
                    call add(match_ids, s:matchaddpos(
                        \ a:args.highlight_colors.secondary,
                        \ [[sublocation[0], sublocation[1]+1, 1]],
                    \ ))
                endfor
            endif
        endfor

    else
        throw "Emotions: Unrecognized highlight type '" . a:args.highlight_type . "'"
    endif

    return match_ids
endfunction

" ask the user which match location they want to go to
" Parameters:
"   Required:
"       "force_uppercase" (number): as s:search_using_pattern
"       "labeled_locations" (hash): a mapping between key input and target
"           cursor location, in the format {'label': [line, col, match_length]}
function! s:prompt_for_labeled_location(args) abort
    let labeled_locations = a:args.labeled_locations
    call s:display_message('Target keys: ', 'Question')
    let input_label = nr2char(getchar())
    if a:args.force_uppercase
        let input_label = toupper(input_label)
    endif
    redraw

    if input_label ==# "\<Esc>"
        call s:display_message('Cancelled', 'None')
        return 0
    elseif has_key(labeled_locations, input_label)
        let location = labeled_locations[input_label]
        " location could be either a simple location, if there is only one
        " possible location corresponding to the given input key
        " or it could be a hash with subkeys, which requires additional user
        " input
        if type(location) == type([])
            return location
        elseif type(location) == type({})
            let input_sublabel = nr2char(getchar())
            if a:args.force_uppercase
                let input_sublabel = toupper(input_sublabel)
            endif
            if has_key(location, input_sublabel)
                return location[input_sublabel]
            else
                call s:display_message(
                    \ "Invalid target '" . input_label . input_sublabel . "'",
                    \ 'WarningMsg'
                \ )
                return 0
            endif
        else
            throw "Internal error: unable to process location" . string(location)
        endif
    else
        call s:display_message("Invalid target '" . input_label . "'", 'WarningMsg')
    endif
endfunction

" Jump to the given location. This also handles the weirdness necessary to
" control inclusive vs. exclusive motions.
" Parameters:
"   Required:
"       "current_operator" (string): if true, we are currently in
"           operator-pending mode trying to resolve this operator
"       "direction" (string): as s:search_using_pattern
"       "include_destination" (string): as s:search_using_pattern
"       "location" (list): [line, col, match_length]
function! s:jump_to_location(args) abort
    let line_number = a:args.location[0]
    let col_number = a:args.location[1]

    " set the context before the jump so the motion can be navigated with
    " context markers
    normal! m`

    " if we're in operator-pending mode,
    " we have to worry about whether to include the destination
    if empty(a:args.current_operator)
        " we don't use 'keepjumps' here because we want to store this movement
        silent call cursor(line_number, col_number)
    else
        " because normal! has to be a complete command, construct the whole
        " command, including the cursor jump, and then execute it at the end
        let motion_command = a:args.current_operator
        if a:args.include_destination && a:args.direction ==# 'forward'
            let motion_command = motion_command . 'v'
        elseif !a:args.include_destination && a:args.direction ==# 'backward'
            let col_number = col_number + 1
            if col_number > col([line_number, '$'])
                let line_number = line_number + 1
                let col_number = 1
            endif
        endif

        silent execute "normal! " . motion_command
            \ . ":call cursor(" .  line_number . ", " . col_number . ")\<CR>"

        " for some reasons 'change' places the cursor in a strange position
        " thank goodness for unit tests
        if a:args.direction ==# 'backward' && a:args.current_operator == 'c'
            silent keepjumps call cursor(line_number, col_number+1)
        endif
    endif
endfunction

" Search for columns by passing into #search#using_pattern
" Parameters:
"   Required:
"       "direction" (string): as in s:search_using_pattern
"       "include_destination" (number): as in s:search_using_pattern
"       "scope" (string): as in s:search_using_pattern
"       "start_of_line" (number): if true, go to the start of the line
"           if false, go to the current cursor position
function! emotions#search_for_column(args, ...) abort
    let current_operator = get(a:000, 0)
    let column = a:args.start_of_line
        \ ? 1
        \ : col('.')
    let pattern = '\v%' . column . 'c'
    call emotions#search_using_pattern({
        \ 'direction': a:args.direction,
        \ 'include_destination': a:args.include_destination,
        \ 'match_length': 1,
        \ 'pattern': pattern,
        \ 'scope': a:args.scope,
    \ }, current_operator)
endfunction

" Search for the last search pattern by passing into #search#using_pattern
" Parameters:
"   Required:
"       "direction" (string): the direction to search in
"           Must be in ['forward', 'backward', 'same', 'reverse']
"           'same' and 'reverse' are relative to the last search direction
"       "include_destination" (number): as in s:search_using_pattern
"       "scope" (string): as in s:search_using_pattern
"       "start_of_line" (number): if true, go to the start of the line
"           if false, go to the current cursor position
function! emotions#search_for_last_search(args, ...) abort
    let current_operator = get(a:000, 0)
    let pattern = getreg('/')
    let direction = a:args.direction

    if direction == "same"
        if v:searchforward
            let direction = 'forward'
        else
            let direction = 'backward'
        endif
    elseif direction == "reverse"
        if v:searchforward
            let direction = 'backward'
        else
            let direction = 'forward'
        endif
    endif

    call emotions#search_using_pattern({
        \ 'direction': direction,
        \ 'include_destination': a:args.include_destination,
        \ 'match_length': 0,
        \ 'pattern': pattern,
        \ 'scope': a:args.scope,
    \ }, current_operator)
endfunction

function! emotions#repeat(args) abort

    if ! has_key(s:last_motion_args, 'pattern')
        call s:display_message("No motion to repeat", 'WarningMsg')
        return
    endif

    call emotions#search_using_pattern({
        \ 'direction': s:last_motion_args.direction,
        \ 'include_destination': s:last_motion_args.include_destination,
        \ 'match_length': s:last_motion_args.match_length,
        \ 'pattern': s:last_motion_args.pattern,
        \ 'repeat': 1,
        \ 'scope': s:last_motion_args.scope,
    \ })
endfunction
