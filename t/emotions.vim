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
            if ! has('conceal')
                SKIP 'Conceal is not enabled'
            elseif ! v:version >= 704
                SKIP 'Conceal only works properly on Vim 7.4+'
            endif
            normal! gg
            normal fea
            Expect CursorInfo() == [1, 2, 'e']
        end

        it 'searches forward with multiple matches'
            if ! has('conceal')
                SKIP 'Conceal is not enabled'
            endif
            normal! gg
            normal fib
            Expect CursorInfo() == [2, 6, 'i']
        end

        it 'ignores case by default'
            if ! has('conceal')
                SKIP 'Conceal is not enabled'
            elseif ! v:version >= 704
                SKIP 'Conceal only works properly on Vim 7.4+'
            endif
            normal! gg
            normal ftb
            Expect CursorInfo() == [2, 11, 't']
        end

        it 'does not search backward'
            if ! has('conceal')
                SKIP 'Conceal is not enabled'
            elseif ! v:version >= 704
                SKIP 'Conceal only works properly on Vim 7.4+'
            endif
            normal! G$
            normal fea
            Expect CursorInfo() == [2, 15, '.']
        end
    end

    context "F"
        it 'searches backward with one match'
            if ! has('conceal')
                SKIP 'Conceal is not enabled'
            elseif ! v:version >= 704
                SKIP 'Conceal only works properly on Vim 7.4+'
            endif
            normal! G$
            normal Fwa
            Expect CursorInfo() == [1, 7, 'w']
        end

        it 'searches backward with multiple matches'
            if ! has('conceal')
                SKIP 'Conceal is not enabled'
            elseif ! v:version >= 704
                SKIP 'Conceal only works properly on Vim 7.4+'
            endif
            normal! G$
            normal Fib
            Expect CursorInfo() == [2, 3, 'i']
        end

        it 'ignores case by default'
            if ! has('conceal')
                SKIP 'Conceal is not enabled'
            elseif ! v:version >= 704
                SKIP 'Conceal only works properly on Vim 7.4+'
            endif
            normal! G$
            normal FTc
            Expect CursorInfo() == [2, 1, 'T']
        end

        it 'does not search forward'
            if ! has('conceal')
                SKIP 'Conceal is not enabled'
            elseif ! v:version >= 704
                SKIP 'Conceal only works properly on Vim 7.4+'
            endif
            normal! gg
            normal Fea
            Expect CursorInfo() == [1, 1, 'H']
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
            normal! gg
            normal fea
            Expect CursorInfo() == [1, 2, 'e']
        end

        it 'searches forward with multiple matches'
            normal! gg
            normal fib
            Expect CursorInfo() == [2, 6, 'i']
        end

        it 'ignores case by default'
            normal! gg
            normal ftb
            Expect CursorInfo() == [2, 11, 't']
        end

        it 'does not search backward'
            normal! G$
            normal fea
            Expect CursorInfo() == [2, 15, '.']
        end
    end

    context "F"
        it 'searches backward with one match'
            normal! G$
            normal Fwa
            Expect CursorInfo() == [1, 7, 'w']
        end

        it 'searches backward with multiple matches'
            normal! G$
            normal Fib
            Expect CursorInfo() == [2, 3, 'i']
        end

        it 'ignores case by default'
            normal! G$
            normal FTc
            Expect CursorInfo() == [2, 1, 'T']
        end

        it 'does not search forward'
            normal! gg
            normal Fea
            Expect CursorInfo() == [1, 1, 'H']
        end
    end
end
