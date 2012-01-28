nnoremap <Leader>vb :ruby Vimbular.match()<CR>
nnoremap <Leader>vc :call InitialiseAndMatch()<CR>

function! InitialiseAndMatch()
  let l:current_window = OpenWindow()
  ruby Vimbular.match()
  let l:back = bufwinnr(l:current_window)
  exe l:back . " wincmd w"
endfunction

function! OpenWindow()
  let current_win = bufname('%')
  let haystack_win = bufwinnr('^_haystack$')
  if ( haystack_win == -1)
    keepjumps silent new _haystack
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  endif
  let results_win = bufwinnr('^_results$')
  if ( results_win == -1)
    keepjumps silent vnew _results
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  endif
  return current_win
endfunction

ruby << EOF
module Vimbular
  def self.match()
    find_windows
    holding_regex = Vim::Buffer.current.line
    if holding_regex =~ /\/(.+)\//
      needle = Regexp.new($~[1])
      haystack = Vim::Window[@haystack_id].buffer[1]
      match_positions = []
      haystack_offset = 0
      while haystack =~ needle
        match_positions << $~.offset(0).map {|pos| pos + haystack_offset}
        haystack = haystack.slice(Range.new($~.offset(0).last,-1))
        haystack_offset = $~.offset(0).last + haystack_offset
      end
      VIM::command("#{@results_id} wincmd w")
      VIM::command('normal! dG')
      VIM::command('syntax clear')
      Vim::Window[@results_id].buffer.line = Vim::Window[@haystack_id].buffer[1]
      match_positions.each do |pos|
        highlight_string = "syntax region Todo start=/\\%#{pos[0]+1}c/ end=/\\%#{pos[1]+1}c/"
        VIM::command(highlight_string)
      end
    end
  end

  private

  def self.find_windows
    windows = Range.new(0,VIM::Window.count,true)
    for window in windows
      if VIM::Window[window].buffer.name =~ /_haystack/
        @haystack_id = window
      end
      if VIM::Window[window].buffer.name =~ /_results/
        @results_id = window
      end
    end
  end
end
EOF
