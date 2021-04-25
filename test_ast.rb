require_relative 'ast'
require 'test/unit'

class AstTest < Test::Unit::TestCase
  def test_string
    program = Program.new(
      [
        LetStatement.new(
          Token.new(:LET, 'let'),
          Identifier.new(Token.new(:IDENT, 'myVar'), 'myVar'),
          Identifier.new(Token.new(:IDENT, 'anotherVar'), 'anotherVar')
        )
      ]
    )

    assert_equal('let myVar = anotherVar;', program.string)
  end
end
