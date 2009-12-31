module CoffeeScript

  # The lexer reads a stream of CoffeeScript and divvys it up into tagged
  # tokens. A minor bit of the ambiguity in the grammar has been avoided by
  # pushing some extra smarts into the Lexer.
  class Lexer

    # The list of keywords passed verbatim to the parser.
    KEYWORDS   = ["if", "else", "then", "unless",
                  "true", "false", "yes", "no", "on", "off",
                  "and", "or", "is", "isnt", "not",
                  "new", "return",
                  "try", "catch", "finally", "throw",
                  "break", "continue",
                  "for", "in", "where", "while",
                  "switch", "when",
                  "super", "extends",
                  "delete", "instanceof", "typeof"]

    # Token matching regexes.
    IDENTIFIER = /\A([a-zA-Z$_]\w*)/
    NUMBER     = /\A((\b|-)((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i
    STRING     = /\A(""|''|"(.*?)[^\\]"|'(.*?)[^\\]')/m
    JS         = /\A(``|`(.*?)[^\\]`)/m
    OPERATOR   = /\A([+\*&|\/\-%=<>:!]+)/
    WHITESPACE = /\A([ \t]+)/
    COMMENT    = /\A(((\n?[ \t]*)?#.*$)+)/
    CODE       = /\A(=>)/
    REGEX      = /\A(\/(.*?)[^\\]\/[imgy]{0,4})/
    MULTI_DENT = /\A((\n([ \t]*)?)+)/
    LAST_DENT  = /\n([ \t]*)/

    # Token cleaning regexes.
    JS_CLEANER = /(\A`|`\Z)/
    MULTILINER = /\n/
    COMMENT_CLEANER = /(^\s*#|\n\s*$)/

    # Assignment tokens.
    ASSIGN     = [':', '=']

    # Tokens that must be balanced.
    BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], [:INDENT, :OUTDENT]]

    # Tokens that signal the start of a balanced pair.
    EXPRESSION_START = [:INDENT,  '{', '(', '[']
    
    # Tokens that signal the end of a balanced pair.
    EXPRESSION_TAIL  = [:OUTDENT, '}', ')', ']']
    
    # Tokens that indicate the close of a clause of an expression.
    EXPRESSION_CLOSE = [:CATCH, :WHEN, :ELSE, :FINALLY] + EXPRESSION_TAIL
    
    # Single-line flavors of block expressions that have unclosed endings.
    # The grammar can't disambiguate them, so we insert the implicit indentation.
    SINGLE_LINERS  = [:ELSE, "=>", :TRY, :FINALLY, :THEN]
    SINGLE_CLOSERS = ["\n", :CATCH, :FINALLY, :ELSE, :OUTDENT, :WHEN]

    # The inverse mappings of token pairs we're trying to fix up.
    INVERSES = {
      :INDENT => :OUTDENT, :OUTDENT => :INDENT, 
      '(' => ')', ')' => '(',
      '{' => '}', '}' => '{', 
      '[' => ']', ']' => '['
    }

    # Scan by attempting to match tokens one character at a time. Slow and steady.
    def tokenize(code)
      @code = code.chomp  # Cleanup code by remove extra line breaks
      @i = 0              # Current character position we're parsing
      @line = 1           # The current line.
      @indent = 0         # The current indent level.
      @indents = []       # The stack of all indent levels we are currently within.
      @tokens = []        # Collection of all parsed tokens in the form [:TOKEN_TYPE, value]
      while @i < @code.length
        @chunk = @code[@i..-1]
        extract_next_token
      end
      puts "original stream: #{@tokens.inspect}" if ENV['VERBOSE']
      close_indentation
      remove_mid_expression_newlines
      move_commas_outside_outdents
      add_implicit_indentation
      ensure_balance(*BALANCED_PAIRS)
      rewrite_closing_parens
      @tokens
    end

    # At every position, run this list of match attempts, short-circuiting if
    # any of them succeed.
    def extract_next_token
      return if identifier_token
      return if number_token
      return if string_token
      return if js_token
      return if regex_token
      return if indent_token
      return if comment_token
      return if whitespace_token
      return    literal_token
    end

    # Matches identifying literals: variables, keywords, method names, etc.
    def identifier_token
      return false unless identifier = @chunk[IDENTIFIER, 1]
      # Keywords are special identifiers tagged with their own name, 'if' will result
      # in an [:IF, "if"] token
      tag = KEYWORDS.include?(identifier) ? identifier.upcase.to_sym : :IDENTIFIER
      @tokens[-1][0] = :PROPERTY_ACCESS if tag == :IDENTIFIER && last_value == '.' && !(@tokens[-2][1] == '.')
      token(tag, identifier)
      @i += identifier.length
    end

    # Matches numbers, including decimals, hex, and exponential notation.
    def number_token
      return false unless number = @chunk[NUMBER, 1]
      token(:NUMBER, number)
      @i += number.length
    end

    # Matches strings, including multi-line strings.
    def string_token
      return false unless string = @chunk[STRING, 1]
      escaped = string.gsub(MULTILINER) do |match|
        @line += 1
        " \\\n"
      end
      token(:STRING, escaped)
      @i += string.length
    end

    # Matches interpolated JavaScript.
    def js_token
      return false unless script = @chunk[JS, 1]
      token(:JS, script.gsub(JS_CLEANER, ''))
      @i += script.length
    end

    # Matches regular expression literals.
    def regex_token
      return false unless regex = @chunk[REGEX, 1]
      token(:REGEX, regex)
      @i += regex.length
    end

    # Matches and consumes comments.
    def comment_token
      return false unless comment = @chunk[COMMENT, 1]
      @line += comment.scan(MULTILINER).length
      token(:COMMENT, comment.gsub(COMMENT_CLEANER, '').split(MULTILINER))
      token("\n", "\n")
      @i += comment.length
    end

    # Record tokens for indentation differing from the previous line.
    def indent_token
      return false unless indent = @chunk[MULTI_DENT, 1]
      @line += indent.scan(MULTILINER).size
      @i += indent.size
      size = indent.scan(LAST_DENT).last.last.length
      return newline_token(indent) if size == @indent
      if size > @indent
        token(:INDENT, size - @indent)
        @indents << (size - @indent)
      else
        outdent_token(@indent - size)
      end
      @indent = size
    end

    def outdent_token(move_out)
      while move_out > 0 && !@indents.empty?
        last_indent = @indents.pop
        token(:OUTDENT, last_indent)
        move_out -= last_indent
      end
      token("\n", "\n")
    end

    # Matches and consumes non-meaningful whitespace.
    def whitespace_token
      return false unless whitespace = @chunk[WHITESPACE, 1]
      @i += whitespace.length
    end

    # Multiple newlines get merged together.
    # Use a trailing \ to escape newlines.
    def newline_token(newlines)
      lines = newlines.scan(MULTILINER).length
      token("\n", "\n") unless ["\n", "\\"].include?(last_value)
      @tokens.pop if last_value == "\\"
      true
    end

    # We treat all other single characters as a token. Eg.: ( ) , . !
    # Multi-character operators are also literal tokens, so that Racc can assign
    # the proper order of operations.
    def literal_token
      value = @chunk[OPERATOR, 1]
      tag_parameters if value && value.match(CODE)
      value ||= @chunk[0,1]
      tag = ASSIGN.include?(value) ? :ASSIGN : value
      token(tag, value)
      @i += value.length
    end

    # Add a token to the results, taking note of the line number, and
    # immediately-preceding comment.
    def token(tag, value)
      @tokens << [tag, Value.new(value, @line)]
    end

    # Peek at the previous token.
    def last_value
      @tokens.last && @tokens.last[1]
    end

    # A source of ambiguity in our grammar was parameter lists in function
    # definitions (as opposed to argument lists in function calls). Tag
    # parameter identifiers in order to avoid this.
    def tag_parameters
      index = 0
      loop do
        tok = @tokens[index -= 1]
        return if !tok
        next if tok[0] == ','
        return if tok[0] != :IDENTIFIER
        tok[0] = :PARAM
      end
    end

    # Close up all remaining open blocks.
    def close_indentation
      outdent_token(@indent)
    end

    # Rewrite the token stream, looking one token ahead and behind.
    def scan_tokens
      i = 0
      while i < @tokens.length
        yield(@tokens[i - 1], @tokens[i], @tokens[i + 1], i)
        i += 1
      end
    end

    # Some blocks occur in the middle of expressions -- when we're expecting
    # this, remove their trailing newlines.
    def remove_mid_expression_newlines
      scan_tokens do |prev, token, post, i|
        @tokens.delete_at(i) if post && EXPRESSION_CLOSE.include?(post[0]) && token[0] == "\n"
      end
    end

    # Make sure that we don't accidentally break trailing commas, which need
    # to go on the outside of expression closers.
    def move_commas_outside_outdents
      scan_tokens do |prev, token, post, i|
        next unless token[0] == :OUTDENT && prev[0] == ','
        @tokens.delete_at(i)
        @tokens.insert(i - 1, token)
      end
    end
    
    # Because our grammar is LALR(1), it can't handle some single-line 
    # expressions that lack ending delimiters. Use the lexer to add the implicit
    # blocks, so it doesn't need to.
    # ')' can close a single-line block, but we need to make sure it's balanced.
    def add_implicit_indentation
      scan_tokens do |prev, token, post, i|
        if SINGLE_LINERS.include?(token[0]) && post[0] != :INDENT && 
          !(token[0] == :ELSE && post[0] == :IF) # Elsifs shouldn't get blocks.
          line = token[1].line
          @tokens.insert(i + 1, [:INDENT, Value.new(2, line)])
          idx = i + 1
          parens = 0
          loop do
            idx += 1
            tok = @tokens[idx]
            if !tok || SINGLE_CLOSERS.include?(tok[0]) || 
                (tok[0] == ')' && parens == 0)
              @tokens.insert(idx, [:OUTDENT, Value.new(2, line)])
              break
            end
            parens += 1 if tok[0] == '('
            parens -= 1 if tok[0] == ')'
          end
          @tokens.delete_at(i) if token[0] == :THEN
        end
      end
    end

    # Ensure that all listed pairs of tokens are correctly balanced throughout
    # the course of the token stream.
    def ensure_balance(*pairs)
      levels = Hash.new(0)
      scan_tokens do |prev, token, post, i|
        pairs.each do |pair|
          open, close = *pair
          levels[open] += 1 if token[0] == open
          levels[open] -= 1 if token[0] == close
          raise ParseError.new(token[0], token[1], nil) if levels[open] < 0
        end
      end
      unclosed = levels.detect {|k, v| v > 0 }
      raise SyntaxError, "unclosed '#{unclosed[0]}'" if unclosed
    end

    # We'd like to support syntax like this:
    #    el.click(event =>
    #      el.hide())
    # In order to accomplish this, move outdents that follow closing parens
    # inwards, safely. The steps to accomplish this are:
    #
    # 1. Check that all paired tokens are balanced and in order.
    # 2. Rewrite the stream with a stack: if you see an '(' or INDENT, add it
    #    to the stack. If you see an ')' or OUTDENT, pop the stack and replace
    #    it with the inverse of what we've just popped.
    # 3. Keep track of "debt" for tokens that we fake, to make sure we end
    #    up balanced in the end.
    #
    def rewrite_closing_parens
      verbose = ENV['VERBOSE']
      stack, debt = [], Hash.new(0)
      stack_stats = lambda { "stack: #{stack.inspect} debt: #{debt.inspect}\n\n" }
      puts "rewrite_closing_original: #{@tokens.inspect}" if verbose
      i = 0
      loop do
        prev, token, post = @tokens[i-1], @tokens[i], @tokens[i+1]
        break unless token
        tag, inv = token[0], INVERSES[token[0]]
        if EXPRESSION_START.include?(tag)
          stack.push(token)
          i += 1
          puts "pushing #{tag} #{stack_stats[]}" if verbose
        elsif EXPRESSION_TAIL.include?(tag)
          puts @tokens[i..-1].inspect if verbose
          # If the tag is already in our debt, swallow it.
          if debt[inv] > 0
            debt[inv] -= 1
            @tokens.delete_at(i)
            puts "tag in debt #{tag} #{stack_stats[]}" if verbose
          else
            # Pop the stack of open delimiters.
            match = stack.pop
            mtag  = match[0]
            # Continue onwards if it's the expected tag.
            if tag == INVERSES[mtag]
              puts "expected tag #{tag} #{stack_stats[]}" if verbose
              i += 1
            else
              # Unexpected close, insert correct close, adding to the debt.
              debt[mtag] += 1
              puts "unexpected #{tag}, replacing with #{INVERSES[mtag]} #{stack_stats[]}" if verbose
              val = mtag == :INDENT ? match[1] : INVERSES[mtag]
              @tokens.insert(i, [INVERSES[mtag], Value.new(val, token[1].line)])
              i += 1
            end
          end
        else
          # Uninteresting token:
          i += 1
        end
      end
    end

  end

end