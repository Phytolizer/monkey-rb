# frozen_string_literal: true

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

  def check_parser_errors(parser)
    parser.errors.each do |error|
      puts "parser error: #{error}"
    end
    assert_equal(0, parser.errors.length)
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
    check_parser_errors(p)

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

  def test_return_statement
    input = <<~END_OF_INPUT
      return 5;
      return 10;
      return 993322;
    END_OF_INPUT

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)
    assert_equal(3, program.statements.length)
    program.statements.each do |stmt|
      assert_instance_of(ReturnStatement, stmt)
      assert_equal('return', stmt.token_literal)
    end
  end

  def test_identifier_expression
    input = 'foobar;'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    assert_equal(1, program.statements.length)
    assert_instance_of(ExpressionStatement, program.statements[0])
    assert_instance_of(Identifier, program.statements[0].expression)
    assert_equal('foobar', program.statements[0].expression.value)
    assert_equal('foobar', program.statements[0].expression.token_literal)
  end
end
