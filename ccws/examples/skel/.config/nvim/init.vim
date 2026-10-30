  set nocompatible
  set viminfo="NONE"
  set nostartofline

"
"
" PLUGINS
"
"
  let mapleader = '|'

  set completeopt=menu
  autocmd FileType python set omnifunc=pythoncomplete#Complete
  autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
  autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
  autocmd FileType css set omnifunc=csscomplete#CompleteCSS
  autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
  autocmd FileType php set omnifunc=phpcomplete#CompletePHP
  autocmd FileType c set omnifunc=ccomplete#Complete

  filetype plugin indent on
  autocmd filetype yaml setlocal ts=4 sw=4 sts=0 expandtab

"
"
" PREFERENCES
"
"
  set mouse=

  set title
  set complete+=k           " scan the files given with the 'dictionary' option
  set shortmess=a "avoid the Hit ENTER to continue prompt
  set history=10
  set backspace=indent,eol,start "allow backspacing over everything in insert mode
  set nomodeline
  set display+=lastline
  set nobackup		"do not keep a backup file, use versions instead
  set history=10  "keep 50 lines of command line history
  set ruler       "show the cursor position all the time
  set viminfo=
  set nowrap
  set ignorecase
  set smartcase
  set noswapfile
  " , -- б  does not work, backslash does not help
  set langmap=йцукенгшщзхъфывапролджэячсмитьюЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ;qwertyuiop[]asdfghjkl\;'zxcvbnm.QWERTYUIOP{}ASDFGHJKL\:\"ZXCVBNM<>
  set autoindent
  set noerrorbells
  set visualbell
  set nojoinspaces
  set fo=tcroqj

" HIGHLIGHTING
  syntax on
  set hlsearch
  let g:load_doxygen_syntax=1
  set background=dark
  highlight cComment ctermfg=darkgreen guifg=darkgreen
  set inccommand=

" TABULATION
  set tabstop=4
  set shiftwidth=4
  set expandtab

" STATUS
  set statusline=%F%m%r%=\ %l\ %c\ fmt=%-4{&fileformat}\ file=%-6{&fileencoding}\ 0x%-2B\ %P
  set laststatus=2


"
"
" KEYS
"
"
  map q gw

  map <C-A> :set fo^=a<CR>

  map <Up> gk
  map <Down> gj
  map <C-N> :noh<CR>
  map <S-Up> <Nop>
  map <S-Down> <Nop>
  imap <S-Up> <Up>
  imap <S-Down> <Down>

  " wordwise yank from line above
  " http://vim.wikia.com/wiki/Wordwise_Ctrl-Y_in_insert_mode
  inoremap <silent> <C-Y> <C-C>:let @z = @"<CR>mz
                        \:exec 'normal!' (col('.')==1 && col('$')==1 ? 'k' : 'kl')<CR>
                        \:exec (col('.')==col('$')-1 ? 'let @" = @_' : 'normal! yw')<CR>
                        \`zp:let @" = @z<CR>a

" ENCODINGS
  set fileencodings=utf-8,koi8-r,cp1251,ibm866
  map <S-F5> :set encoding=koi8-r<CR>
  map <S-F6> :set encoding=8bit-cp1251<CR>
  map <S-F7> :set encoding=8bit-cp866<CR>
  map <S-F8> :set encoding=utf8<CR>
  map <F5> :e ++enc=koi8-r<CR>
  map <F6> :e ++enc=cp1251<CR>
  map <F7> :e ++enc=ibm866<CR>
  map <F8> :e ++enc=utf-8<CR>
  map <C-F5> :set fileformat=unix<CR>
  map <C-F6> :set fileformat=dos<CR>
  map <C-F7> :set fileformat=mac<CR>

" TOOLS
  map <F1> :wa<CR>:make<CR>
  map <F2> :cope<CR>
  map <F3> :cn<CR>
  map <F4> :cp<CR>

" EXIT
  map <F9>  :set titlestring=_<CR>:q!<CR>
  map <F10> :set titlestring=_<CR>:qa<CR>
  map <F11> :norm!mw<CR>:%s/\s\+$//e<CR>:norm!`w<CR>:delmarks w<CR>:noh<CR>:wa!<CR>:set titlestring=_<CR>:q!<CR>
  map <F12> :norm!mw<CR>:%s/\s\+$//e<CR>:norm!`w<CR>:delmarks w<CR>:noh<CR>:wa!<CR>

" NAVIGATION
  map <S-F11> :foldclose<CR>
  map <S-F12> :foldopen<CR>
  nnoremap <C-Right> :bn!<CR>
  nnoremap <C-Left> :bp!<CR>

" map control-backspace to delete the previous word
  map <C-BS>  <Esc>vBc

" now _F will display which function you are currently in.
  map _F ma[[k"xyy`a:echo @x<CR>



com! -range CFMY :<line1>,<line2>!clang-format --style="{
            \    'AccessModifierOffset': -4,
            \    'AlignAfterOpenBracket': 'AlwaysBreak',
            \    'AlignEscapedNewlinesLeft': false,
            \    'AlignTrailingComments': true,
            \    'AllowAllParametersOfDeclarationOnNextLine': false,
            \    'AllowShortFunctionsOnASingleLine': 'None',
            \    'AllowShortIfStatementsOnASingleLine': false,
            \    'AllowShortLoopsOnASingleLine': false,
            \    'AlwaysBreakBeforeMultilineStrings': false,
            \    'AlwaysBreakTemplateDeclarations': true,
            \    'BasedOnStyle': 'Google',
            \    'BinPackArguments': false,
            \    'BinPackParameters': false,
            \    'BreakBeforeBinaryOperators': 'NonAssignment',
            \    'BreakBeforeBraces': 'Allman',
            \    'BreakBeforeTernaryOperators': false,
            \    'BreakConstructorInitializersBeforeComma': true,
            \    'BreakStringLiterals': false,
            \    'ColumnLimit': 120,
            \    'ConstructorInitializerAllOnOneLineOrOnePerLine': true,
            \    'ConstructorInitializerIndentWidth': 2,
            \    'ContinuationIndentWidth': 8,
            \    'Cpp11BracedListStyle': false,
            \    'DerivePointerAlignment': false,
            \    'DerivePointerBinding': true,
            \    'ExperimentalAutoDetectBinPacking': false,
            \    'FixNamespaceComments': true,
            \    'IndentCaseLabels': true,
            \    'IndentFunctionDeclarationAfterType': false,
            \    'IndentPPDirectives': 'AfterHash',
            \    'IndentWidth': 4,
            \    'IndentWrappedFunctionNames': true,
            \    'MaxEmptyLinesToKeep': 3,
            \    'NamespaceIndentation': 'All',
            \    'ObjCSpaceBeforeProtocolList': true,
            \    'PenaltyBreakBeforeFirstCallParameter': 19,
            \    'PenaltyBreakComment': 60,
            \    'PenaltyBreakFirstLessLess': 1000,
            \    'PenaltyBreakString': 1,
            \    'PenaltyExcessCharacter': 500,
            \    'PenaltyReturnTypeOnItsOwnLine': 1000,
            \    'PointerAlignment': 'Right',
            \    'PointerBindsToType': false,
            \    'SortIncludes': false,
            \    'SpaceAfterControlStatementKeyword': true,
            \    'SpaceBeforeAssignmentOperators': true,
            \    'SpaceInEmptyParentheses': false,
            \    'SpacesBeforeTrailingComments': 2,
            \    'SpacesInAngles': false,
            \    'SpacesInCStyleCastParentheses': false,
            \    'SpacesInParentheses': false,
            \    'Standard': 'Cpp11',
            \    'TabWidth': 4,
            \    'UseTab': 'Never',
            \}"<CR>


map <F3> :norm!mw<CR>:%CFMY<CR>:norm!`w<CR>:delmarks w<CR><CR>
vmap <F3> :CFMY<CR>
