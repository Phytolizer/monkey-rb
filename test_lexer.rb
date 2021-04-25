require_relative 'lexer'
require 'test/unit'

class TestLexer < Test::Unit::TestCase
  def test_next_token
    input = '=+(){},;'
    tests = [
      [:ASSIGN, '='],
      [:PLUS, '+'],
      [:LPAREN, '('],
      [:RPAREN, ')'],
      [:LBRACE, '{'],
      [:RBRACE, '}'],
      [:COMMA, ','],
      [:SEMICOLON, ';']
    ]

    l = Lexer.new(input)

    tests.each_with_index do |test, _i|
      tok = l.next_token
      assert_equal(tok.type, test[0])
      assert_equal(tok.literal, test[1])
    end
  end
end
