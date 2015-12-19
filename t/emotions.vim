" Don't source test files
if expand("%:p") ==# expand("<sfile>:p")
    finish
endif

let s:root_dir = matchstr(system('git rev-parse --show-cdup'), '[^\n]\+')
execute 'set' 'rtp +=./'.s:root_dir
runtime! plugin/emotions.vim

" return [line_number, col_number, current_character]
function! CursorInfo()
    return [line('.'), col('.'), getline('.')[col('.')-1]]
endfunction

function! CreateBuffer()
    new
    " add emotions mappings
    map <buffer> f <Plug>(emotions-f)
    map <buffer> F <Plug>(emotions-F)
    map <buffer> t <Plug>(emotions-t)
    map <buffer> T <Plug>(emotions-T)
    call append(line('$'), ['Hello world.', 'This is a test.'])
    " remove the blank first line
    normal! ggdd
    " the buffer now has two lines: 'Hello World', and 'This is a test'
endfunction

describe 'Default config'

    it 'has global variables'
        Expect g:emotions_create_commands                  == 1
        Expect g:emotions_create_commands                  == 1
        Expect g:emotions_create_find_mappings             == 1
        Expect g:emotions_create_ijkl_mappings             == 0
        Expect g:emotions_create_word_mappings             == 1
        Expect g:emotions_enable_shading                   == 0
        Expect g:emotions_find_mapping_prefix              == '<Leader>'
        Expect g:emotions_force_uppercase                  == 1
        Expect g:emotions_highlight_type                   == (has('conceal') && v:version >= 704) ? 'conceal' : 'single'
        Expect g:emotions_ijkl_mapping_prefix              == '<Leader>'
        Expect g:emotions_match_separation_distance        == 2
        Expect g:emotions_keys                             == 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        Expect g:emotions_replace_full_match               == 0
        Expect g:emotions_shade_highlight_group            == 'Comment'
        Expect g:emotions_skip_folded_lines                == 1
        Expect g:emotions_target_highlight_group_primary   == 'IncSearch'
        Expect g:emotions_target_highlight_group_secondary == 'Search'
        Expect g:emotions_word_mapping_prefix              == '<Leader>'
    end

    context 'has <Plug> mappings'
        it 'for f'
            Expect maparg('<Plug>(emotions-f)', 'n') == ":<C-U>call emotions#search_for_characters({'direction': 'forward', 'scope': 'direction', 'include_destination': 1, 'character_count': 1})<CR>"
            Expect maparg('<Plug>(emotions-f)', 'o') == "<Esc>:<C-U>call emotions#search_for_characters({'direction': 'forward', 'scope': 'direction', 'include_destination': 1, 'character_count': 1}, v:operator)<CR>"
        end

        it 'for F'
            Expect maparg('<Plug>(emotions-F)', 'n') == ":<C-U>call emotions#search_for_characters({'direction': 'backward', 'scope': 'direction', 'include_destination': 1, 'character_count': 1})<CR>"
            Expect maparg('<Plug>(emotions-F)', 'o') == "<Esc>:<C-U>call emotions#search_for_characters({'direction': 'backward', 'scope': 'direction', 'include_destination': 1, 'character_count': 1}, v:operator)<CR>"
        end

        it 'for t'
            Expect maparg('<Plug>(emotions-t)', 'n') == ":<C-U>call emotions#search_for_characters({'direction': 'forward', 'scope': 'direction', 'include_destination': 0, 'character_count': 1})<CR>"
            Expect maparg('<Plug>(emotions-t)', 'o') == "<Esc>:<C-U>call emotions#search_for_characters({'direction': 'forward', 'scope': 'direction', 'include_destination': 0, 'character_count': 1}, v:operator)<CR>"
        end

        it 'for T'
            Expect maparg('<Plug>(emotions-T)', 'n') == ":<C-U>call emotions#search_for_characters({'direction': 'backward', 'scope': 'direction', 'include_destination': 0, 'character_count': 1})<CR>"
            Expect maparg('<Plug>(emotions-T)', 'o') == "<Esc>:<C-U>call emotions#search_for_characters({'direction': 'backward', 'scope': 'direction', 'include_destination': 0, 'character_count': 1}, v:operator)<CR>"
        end
    end
end

function! s:check_skip_conceal()
    if ! has('conceal')
        SKIP 'Conceal is not enabled'
    elseif v:version < 704
        SKIP 'Conceal only works properly on Vim 7.4+'
    endif
endfunction

" we store all the key mapping tests in this dictionary
" this help standardize tests between the different modes
" such as conceal-based vs. replacement-based
let s:test = {
    \ 'f': {},
    \ 'F': {},
    \ 't': {},
    \ 'T': {},
\ }

" tests for "f"

    function! s:test.f.one_match()
        normal! gg
        normal fea
        Expect CursorInfo() == [1, 2, 'e']
    endfunction

    function! s:test.f.multiple_matches()
        normal! gg
        normal fea
        Expect CursorInfo() == [1, 2, 'e']
    endfunction

    function! s:test.f.ignore_case()
        normal! gg
        normal ftb
        Expect CursorInfo() == [2, 11, 't']
    endfunction

    function! s:test.f.direction()
        normal! G$
        normal fea
        Expect CursorInfo() == [2, 15, '.']
    endfunction

    function! s:test.f.change()
        normal! gg
        execute "normal cfoaHi\<Esc>"
        Expect getline('.') == 'Hi world.'
    endfunction

    function! s:test.f.delete()
        normal! gg
        normal dfoa
        Expect getline('.') == ' world.'
    endfunction

    function! s:test.f.yank()
        normal! gg
        normal yfoaP
        Expect getline('.') == 'HelloHello world.'
    endfunction

" tests for "F"

    function! s:test.F.one_match()
        normal! G$
        normal Fwa
        Expect CursorInfo() == [1, 7, 'w']
    endfunction

    function! s:test.F.multiple_matches()
        normal! G$
        normal Fib
        Expect CursorInfo() == [2, 3, 'i']
    endfunction

    function! s:test.F.ignore_case()
        normal! G$
        normal FTc
        Expect CursorInfo() == [2, 1, 'T']
    endfunction

    function! s:test.F.direction()
        normal! gg
        normal Fea
        Expect CursorInfo() == [1, 1, 'H']
    endfunction

    function! s:test.F.change()
        normal! gg$
        execute "normal cFwaplanet\<Esc>"
        Expect getline('.') == 'Hello planet.'
    endfunction

    function! s:test.F.delete()
        normal! gg$
        normal dFwa
        Expect getline('.') == 'Hello .'
    endfunction

    function! s:test.F.yank()
        normal! gg$
        " note that the cursor moves when yanking backwards, but not forwards
        " this is the same as Vim's normal behavior
        normal yFwaP
        Expect getline('.') == 'Hello worldworld.'
    endfunction

" tests for "t"

    function! s:test.t.one_match()
        normal! gg
        normal tea
        Expect CursorInfo() == [1, 2, 'e']
    endfunction

    function! s:test.t.multiple_matches()
        normal! gg
        normal tea
        Expect CursorInfo() == [1, 2, 'e']
    endfunction

    function! s:test.t.ignore_case()
        normal! gg
        normal ttb
        Expect CursorInfo() == [2, 11, 't']
    endfunction

    function! s:test.t.direction()
        normal! G$
        normal tea
        Expect CursorInfo() == [2, 15, '.']
    endfunction

    function! s:test.t.change()
        normal! gg
        execute "normal ctoaHi\<Esc>"
        Expect getline('.') == 'Hio world.'
    endfunction

    function! s:test.t.delete()
        normal! gg
        normal dtoa
        Expect getline('.') == 'o world.'
    endfunction

    function! s:test.t.yank()
        normal! gg
        normal ytoaP
        Expect getline('.') == 'HellHello world.'
    endfunction

" tests for "T"

    function! s:test.T.one_match()
        normal! G$
        normal Twa
        Expect CursorInfo() == [1, 7, 'w']
    endfunction

    function! s:test.T.multiple_matches()
        normal! G$
        normal Tib
        Expect CursorInfo() == [2, 3, 'i']
    endfunction

    function! s:test.T.ignore_case()
        normal! G$
        normal TTc
        Expect CursorInfo() == [2, 1, 'T']
    endfunction

    function! s:test.T.direction()
        normal! gg
        normal Tea
        Expect CursorInfo() == [1, 1, 'H']
    endfunction

    function! s:test.T.change()
        normal! gg$
        execute "normal cTwaplanet\<Esc>"
        Expect getline('.') == 'Hello wplanet.'
    endfunction

    function! s:test.T.delete()
        normal! gg$
        normal dTwa
        Expect getline('.') == 'Hello w.'
    endfunction

    function! s:test.T.yank()
        normal! gg$
        " note that the cursor moves when yanking backwards, but not forwards
        " this is the same as Vim's normal behavior
        normal yTwaP
        Expect getline('.') == 'Hello worldorld.'
    endfunction

" calling the tests using vspec

describe 'Conceal-based'
    before
        let g:emotions_highlight_type = 'conceal'
        call CreateBuffer()
    end

    after
        close!
    end

    it 'is enabled'
        Expect g:emotions_highlight_type == 'conceal'
    end

    context "f"
        it 'searches forward with one match'
            call s:check_skip_conceal()
            call s:test.f.one_match()
        end

        it 'searches forward with multiple matches'
            call s:check_skip_conceal()
            call s:test.f.multiple_matches()
        end

        it 'ignores case by default'
            call s:check_skip_conceal()
            call s:test.f.ignore_case()
        end

        it 'does not search backward'
            call s:check_skip_conceal()
            call s:test.f.direction()
        end

        it "changes text with 'c'"
            call s:check_skip_conceal()
            call s:test.f.change()
        end

        it "deletes text with 'd'"
            call s:check_skip_conceal()
            call s:test.f.delete()
        end

        it "yanks text with 'y'"
            call s:check_skip_conceal()
            call s:test.f.yank()
        end
    end

    context "F"
        it 'searches backward with one match'
            call s:check_skip_conceal()
            call s:test.F.one_match()
        end

        it 'searches backward with multiple matches'
            call s:check_skip_conceal()
            call s:test.F.multiple_matches()
        end

        it 'ignores case by default'
            call s:check_skip_conceal()
            call s:test.F.ignore_case()
        end

        it 'does not search forward'
            call s:check_skip_conceal()
            call s:test.F.direction()
        end

        it "changes text with 'c'"
            call s:check_skip_conceal()
            call s:test.F.change()
        end

        it "deletes text with 'd'"
            call s:check_skip_conceal()
            call s:test.F.delete()
        end

        it "yanks text with 'y'"
            call s:check_skip_conceal()
            call s:test.F.yank()
        end
    end

    context "t"
        it 'searches forward with one match'
            call s:check_skip_conceal()
            call s:test.t.one_match()
        end

        it 'searches forward with multiple matches'
            call s:check_skip_conceal()
            call s:test.t.multiple_matches()
        end

        it 'ignores case by default'
            call s:check_skip_conceal()
            call s:test.t.ignore_case()
        end

        it 'does not search backward'
            call s:check_skip_conceal()
            call s:test.t.direction()
        end

        it "changes text with 'c'"
            call s:check_skip_conceal()
            call s:test.t.change()
        end

        it "deletes text with 'd'"
            call s:check_skip_conceal()
            call s:test.t.delete()
        end

        it "yanks text with 'y'"
            call s:check_skip_conceal()
            call s:test.t.yank()
        end
    end

    context "T"
        it 'searches backward with one match'
            call s:check_skip_conceal()
            call s:test.T.one_match()
        end

        it 'searches backward with multiple matches'
            call s:check_skip_conceal()
            call s:test.T.multiple_matches()
        end

        it 'ignores case by default'
            call s:check_skip_conceal()
            call s:test.T.ignore_case()
        end

        it 'does not search forward'
            call s:check_skip_conceal()
            call s:test.T.direction()
        end

        it "changes text with 'c'"
            call s:check_skip_conceal()
            call s:test.T.change()
        end

        it "deletes text with 'd'"
            call s:check_skip_conceal()
            call s:test.T.delete()
        end

        it "yanks text with 'y'"
            call s:check_skip_conceal()
            call s:test.T.yank()
        end
    end
end

describe 'Single replacement-based'
    before
        let g:emotions_highlight_type='single'
        call CreateBuffer()
    end

    after
        close!
    end

    it 'is enabled'
        Expect g:emotions_highlight_type == 'single'
    end

    context "f"
        it 'searches forward with one match'
            call s:test.f.one_match()
        end

        it 'searches forward with multiple matches'
            call s:test.f.multiple_matches()
        end

        it 'ignores case by default'
            call s:test.f.ignore_case()
        end

        it 'does not search backward'
            call s:test.f.direction()
        end

        it "changes text with 'c'"
            call s:test.f.change()
        end

        it "deletes text with 'd'"
            call s:test.f.delete()
        end

        it "yanks text with 'y'"
            call s:test.f.yank()
        end
    end

    context "F"
        it 'searches backward with one match'
            call s:test.F.one_match()
        end

        it 'searches backward with multiple matches'
            call s:test.F.multiple_matches()
        end

        it 'ignores case by default'
            call s:test.F.ignore_case()
        end

        it 'does not search forward'
            call s:test.F.direction()
        end

        it "deletes text with 'd'"
            call s:test.F.delete()
        end

        it "changes text with 'c'"
            call s:test.F.change()
        end

        it "yanks text with 'y'"
            call s:test.F.yank()
        end
    end

    context "t"
        it 'searches forward with one match'
            call s:test.t.one_match()
        end

        it 'searches forward with multiple matches'
            call s:test.t.multiple_matches()
        end

        it 'ignores case by default'
            call s:test.t.ignore_case()
        end

        it 'does not search backward'
            call s:test.t.direction()
        end

        it "changes text with 'c'"
            call s:test.t.change()
        end

        it "deletes text with 'd'"
            call s:test.t.delete()
        end

        it "yanks text with 'y'"
            call s:test.t.yank()
        end
    end

    context "T"
        it 'searches backward with one match'
            call s:test.T.one_match()
        end

        it 'searches backward with multiple matches'
            call s:test.T.multiple_matches()
        end

        it 'ignores case by default'
            call s:test.T.ignore_case()
        end

        it 'does not search forward'
            call s:test.T.direction()
        end

        it "changes text with 'c'"
            call s:test.T.change()
        end

        it "deletes text with 'd'"
            call s:test.T.delete()
        end

        it "yanks text with 'y'"
            call s:test.T.yank()
        end
    end
end
