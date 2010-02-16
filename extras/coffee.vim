" Vim syntax file
" Language:	CoffeeScript
" Maintainer:	Jeff Olson <olson.jeffery@gmail.com>
" URL:		http://github.com/olsonjeffery
" Changes:	(jro) initial port from javascript
" Last Change:	2006 Jun 19
" Adaptation of javascript.vim syntax file (distro'd w/ vim72), 
" maintained by Claudio Fleiner <claudio@fleiner.com>
" with updates from Scott Shattuck (ss) <ss@technicalpursuit.com>

if !exists("main_syntax")
  if version < 600
    syntax clear
  elseif exists("b:current_syntax")
    finish
  endif
  let main_syntax = 'coffee'
endif

syn case ignore

syn match   coffeeLineComment      "#.*" contains=@Spell,CoffeeCommentTodo
syn match   coffeeSpecial	       "\\\d\d\d\|\\."
syn region  coffeeStringD	       start=+"+  skip=+\\\\\|\\"+  end=+"\|$+  contains=coffeeSpecial,@htmlPreproc
syn region  coffeeStringS	       start=+'+  skip=+\\\\\|\\'+  end=+'\|$+  contains=coffeeSpecial,@htmlPreproc

syn match   coffeeSpecialCharacter "'\\.'"
syn match   coffeeNumber	       "-\=\<\d\+L\=\>\|0[xX][0-9a-fA-F]\+\>"
syn region  coffeeRegexpString     start=+/[^/*]+me=e-1 skip=+\\\\\|\\/+ end=+/[gi]\{0,2\}\s*$+ end=+/[gi]\{0,2\}\s*[;.,)\]}]+me=e-1 contains=@htmlPreproc oneline

syn match coffeeFunctionParams "([^)]*)\s*->"
syn match coffeeBindFunctionParams "([^)]*)\s*=>"
syn match coffeePrototypeAccess "::"
syn match coffeeBindFunction "=[1]>[1]"
syn match coffeeFunction "->"

syn keyword coffeeExtends   extends
syn keyword coffeeConditional	if else switch then not
syn keyword coffeeRepeat		while for in of
syn keyword coffeeBranch		break continue
syn keyword coffeeOperator		delete instanceof typeof
syn keyword coffeeType		Array Boolean Date Function Number Object String RegExp
syn keyword coffeeStatement		return with
syn keyword coffeeBoolean		true false
syn keyword coffeeNull		null undefined
syn keyword coffeeIdentifier	arguments this var
syn keyword coffeeLabel		case default
syn keyword coffeeException		try catch finally throw
syn keyword coffeeMessage		alert confirm prompt status
syn keyword coffeeGlobal		self window top parent
syn keyword coffeeMember		document event location 
syn keyword coffeeDeprecated	escape unescape
syn keyword coffeeReserved		abstract boolean byte char class const debugger double enum export final float goto implements import int interface long native package private protected public short static super synchronized throws transient volatile 

syn sync fromstart
syn sync maxlines=100

if main_syntax == "coffee"
  syn sync ccomment coffeeComment
endif

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_coffee_syn_inits")
  if version < 508
    let did_coffee_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink coffeePrototypeAccess Keyword
  HiLink coffeeExtends        Keyword
  HiLink coffeeLineComment		Comment
  HiLink coffeeSpecial		Special
  HiLink coffeeStringS		String
  HiLink coffeeStringD		String
  HiLink coffeeCharacter		Character
  HiLink coffeeSpecialCharacter	coffeeSpecial
  HiLink coffeeNumber		coffeeValue
  HiLink coffeeConditional		Conditional
  HiLink coffeeRepeat		Repeat
  HiLink coffeeBranch		Conditional
  HiLink coffeeOperator		Operator
  HiLink coffeeType			Type
  HiLink coffeeStatement		Statement
  HiLink coffeeBindFunctionParams		Function
  HiLink coffeeFunctionParams		Function
  HiLink coffeeFunction		Function
  HiLink coffeeBindFunction		Function
  HiLink coffeeBraces		Function
  HiLink coffeeError		Error
  HiLink coffeeScrParenError		coffeeError
  HiLink coffeeNull			Keyword
  HiLink coffeeBoolean		Boolean
  HiLink coffeeRegexpString		String

  HiLink coffeeIdentifier		Identifier
  HiLink coffeeLabel		Label
  HiLink coffeeException		Exception
  HiLink coffeeMessage		Keyword
  HiLink coffeeGlobal		Keyword
  HiLink coffeeMember		Keyword
  HiLink coffeeDeprecated		Exception 
  HiLink coffeeReserved		Keyword
  HiLink coffeeDebug		Debug
  HiLink coffeeConstant		Label

  delcommand HiLink
endif

let b:current_syntax = "coffee"
if main_syntax == 'coffee'
  unlet main_syntax
endif

" vim: ts=8
