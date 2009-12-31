module CoffeeScript

  # In order to keep the grammar simple, the stream of tokens that the Lexer
  # emits is rewritten by the Rewriter, smoothing out ambiguities, mis-nested
  # indentation, and single-line flavors of expressions.
  class Rewriter

    # Tokens that must be balanced.
    BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], [:INDENT, :OUTDENT]]

    # Tokens that signal the start of a balanced pair.
    EXPRESSION_START = BALANCED_PAIRS.map {|pair| pair.first }

    # Tokens that signal the end of a balanced pair.
    EXPRESSION_TAIL  = BALANCED_PAIRS.map {|pair| pair.last }

    # Tokens that indicate the close of a clause of an expression.
    EXPRESSION_CLOSE = [:CATCH, :WHEN, :ELSE, :FINALLY] + EXPRESSION_TAIL

    # The inverse mappings of token pairs we're trying to fix up.
    INVERSES = BALANCED_PAIRS.inject({}) do |memo, pair|
      memo[pair.first] = pair.last
      memo[pair.last]  = pair.first
      memo
    end

    # Single-line flavors of block expressions that have unclosed endings.
    # The grammar can't disambiguate them, so we insert the implicit indentation.
    SINGLE_LINERS  = [:ELSE, "=>", :TRY, :FINALLY, :THEN]
    SINGLE_CLOSERS = ["\n", :CATCH, :FINALLY, :ELSE, :OUTDENT, :WHEN]

    def initialize(lexer)
      @lexer = lexer
    end

    def rewrite(tokens)
      @tokens = tokens
      adjust_comments
      remove_mid_expression_newlines
      move_commas_outside_outdents
      add_implicit_indentation
      ensure_balance(*BALANCED_PAIRS)
      rewrite_closing_parens
      @tokens
    end

    # Rewrite the token stream, looking one token ahead and behind.
    def scan_tokens
      i = 0
      while i < @tokens.length
        yield(@tokens[i - 1], @tokens[i], @tokens[i + 1], i)
        i += 1
      end
    end

    # Massage newlines and indentations so that comments don't have to be
    # correctly indented, or appear on their own line.
    def adjust_comments
      scan_tokens do |prev, token, post, i|
        next unless token[0] == :COMMENT
        before, after = @tokens[i - 2], @tokens[i + 2]
        if before && after &&
            ((before[0] == :INDENT && after[0] == :OUTDENT) ||
            (before[0] == :OUTDENT && after[0] == :INDENT)) &&
            before[1] == after[1]
          @tokens.delete_at(i + 2)
          @tokens.delete_at(i - 2)
        elsif !["\n", :INDENT, :OUTDENT].include?(prev[0])
          @tokens.insert(i, ["\n", Value.new("\n", token[1].line)])
        end
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