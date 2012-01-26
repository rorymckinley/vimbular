nnoremap <Leader>vb :ruby Vimbular.match()<CR>
nnoremap <Leader>vc :call InitialiseAndMatch()<CR>

function! InitialiseAndMatch()
  let s:windowParms = OpenWindow()
  :ruby Vimbular.match()
endfunction

function! OpenWindow()
  let haystack_win = bufwinnr('^_haystack$')
  if ( haystack_win == -1)
    keepjump silent new _haystack
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  endif
  let results_win = bufwinnr('^_results$')
  if ( results_win == -1)
    keepjump silent vnew _results
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  endif
  let haystack_win = bufwinnr('^_haystack$')
  let results_win = bufwinnr('^_results$')
  return [haystack_win, results_win]
endfunction

ruby << EOF
module Vimbular
  def self.build_windows
  end

  def self.match()
    holding_regex = Vim::Buffer.current.line
    puts "here"
    holding_regex =~ /\/(.+)\//
    needle = Regexp.new($~[1])
    haystack = Vim::Window[1].buffer[1]
    match_positions = []
    haystack_offset = 0
    while haystack =~ needle
      match_positions << $~.offset(0).map {|pos| pos + haystack_offset}
      haystack = haystack.slice(Range.new($~.offset(0).last,-1))
      haystack_offset = $~.offset(0).last + haystack_offset
    end
    VIM::command('0 wincmd w')
    VIM::command('normal! dG')
    VIM::command('syntax clear')
    VIM::command('w!')
    Vim::Window[0].buffer.line = Vim::Window[1].buffer[1]
    match_positions.each do |pos|
    highlight_string = "syntax region Todo start=/\\%#{pos[0]+1}c/ end=/\\%#{pos[1]+1}c/"
    VIM::command(highlight_string)
    end
  end
end
EOF
