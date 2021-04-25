require_relative 'lexer'
require 'test/unit'

class TestLexer < Test::Unit::TestCase
  def test_next_token
    input = <<~END_OF_INPUT
      let five = 5;
      let ten = 10;

      let add = fn(x, y) {
        x + y;
      };

      let result = add(five, ten);
    END_OF_INPUT
    tests = [
      [:LET, 'let'],
      [:IDENT, 'five'],
      [:ASSIGN, '='],
      [:INT, '5'],
      [:SEMICOLON, ';'],
      [:LET, 'let'],
      [:IDENT, 'ten'],
      [:ASSIGN, '='],
      [:INT, '10'],
      [:SEMICOLON, ';'],
      [:LET, 'let'],
      [:IDENT, 'add'],
      [:ASSIGN, '='],
      [:FUNCTION, 'fn'],
      [:LPAREN, '('],
      [:IDENT, 'x'],
      [:COMMA, ','],
      [:IDENT, 'y'],
      [:RPAREN, ')'],
      [:LBRACE, '{'],
      [:IDENT, 'x'],
      [:PLUS, '+'],
      [:IDENT, 'y'],
      [:SEMICOLON, ';'],
      [:RBRACE, '}'],
      [:SEMICOLON, ';'],
      [:LET, 'let'],
      [:IDENT, 'result'],
      [:ASSIGN, '='],
      [:IDENT, 'add'],
      [:LPAREN, '('],
      [:IDENT, 'five'],
      [:COMMA, ','],
      [:IDENT, 'ten'],
      [:RPAREN, ')'],
      [:SEMICOLON, ';']
    ]

    l = Lexer.new(input)

    tests.each_with_index do |test, _i|
      tok = l.next_token
      assert_not_nil(tok)
      assert_equal(test[0], tok.type)
      assert_equal(test[1], tok.literal)
    end
  end
end
