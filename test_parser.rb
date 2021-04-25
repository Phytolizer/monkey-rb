require_relative 'lexer'
require_relative 'parser'
require_relative 'ast'
require 'test/unit'

class TestParser < Test::Unit::TestCase
  private

  def check_let_statement(expected, actual)
    assert_equal('let', actual.token_literal)
    assert_instance_of(LetStatement, actual)
    assert_equal(expected, actual.name.value)
    assert_equal(expected, actual.name.token_literal)
  end

  public

  def test_let_statement
    input = <<~END_OF_INPUT
      let x = 5;
      let y = 10;
      let foobar = 838383;
    END_OF_INPUT

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    assert_not_nil(program)

    assert_equal(3, program.statements.length)
    tests = %w[
      x
      y
      foobar
    ]

    tests.each_with_index do |test, i|
      stmt = program.statements[i]
      check_let_statement(test, stmt)
    end
  end
end
