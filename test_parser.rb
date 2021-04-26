# frozen_string_literal: true

require_relative 'lexer'
require_relative 'parser'
require_relative 'ast'
require 'test/unit'

## Extensive tests for the Monkey parser.
## There is lots of room for improvement here.
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

  def check_integer_literal(expected, actual)
    assert_instance_of(IntegerLiteral, actual)
    assert_equal(expected, actual.value)
    assert_equal(expected.to_s, actual.token_literal)
  end

  def check_identifier(expected, actual)
    assert_instance_of(Identifier, actual)
    assert_equal(expected, actual.value)
    assert_equal(expected, actual.token_literal)
  end

  def check_boolean_literal(expected, actual)
    assert_instance_of(Boolean, actual)
    assert_equal(expected, actual.value)
    assert_equal(expected.to_s, actual.token_literal)
  end

  def check_literal_expression(expected, actual)
    case expected
    when Integer
      check_integer_literal(expected, actual)
    when String
      check_identifier(expected, actual)
    when TrueClass, FalseClass
      check_boolean_literal(expected, actual)
    end
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

  def test_integer_literal
    input = '5;'

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    assert_equal(1, program.statements.length)
    stmt = program.statements[0]
    assert_instance_of(ExpressionStatement, stmt)
    literal = stmt.expression
    assert_instance_of(IntegerLiteral, literal)
    assert_equal(5, literal.value)
    assert_equal('5', literal.token_literal)
  end

  def test_prefix_expressions
    tests = [
      ['!5;', '!', 5],
      ['-15;', '-', 15],
      ['!true;', '!', true],
      ['!false;', '!', false]
    ]

    tests.each do |test|
      l = Lexer.new(test[0])
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)
      assert_equal(1, program.statements.length)
      stmt = program.statements[0]
      assert_instance_of(ExpressionStatement, stmt)
      exp = stmt.expression
      assert_instance_of(PrefixExpression, exp)
      assert_equal(test[1], exp.operator)
      check_literal_expression(test[2], exp.right)
    end
  end

  def test_infix_expressions
    tests = [
      ['5 + 5;', 5, '+', 5],
      ['5 - 5;', 5, '-', 5],
      ['5 * 5;', 5, '*', 5],
      ['5 / 5;', 5, '/', 5],
      ['5 < 5;', 5, '<', 5],
      ['5 > 5;', 5, '>', 5],
      ['5 == 5;', 5, '==', 5],
      ['5 != 5;', 5, '!=', 5],
      ['true == true;', true, '==', true],
      ['true != false;', true, '!=', false],
      ['false == false', false, '==', false]
    ]

    tests.each do |test|
      l = Lexer.new(test[0])
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)

      assert_equal(program.statements.length, 1)
      stmt = program.statements[0]
      assert_instance_of(ExpressionStatement, stmt)
      exp = stmt.expression
      assert_instance_of(InfixExpression, exp)
      check_literal_expression(test[1], exp.left)
      assert_equal(test[2], exp.operator)
      check_literal_expression(test[3], exp.right)
    end
  end

  def test_operator_precedence
    tests = [
      ['-a * b', '((-a) * b)'],
      ['!-a', '(!(-a))'],
      ['a + b + c', '((a + b) + c)'],
      ['a + b - c', '((a + b) - c)'],
      ['a * b * c', '((a * b) * c)'],
      ['a * b / c', '((a * b) / c)'],
      ['a + b / c', '(a + (b / c))'],
      ['a + b * c + d / e - f', '(((a + (b * c)) + (d / e)) - f)'],
      ['3 + 4; -5 * 5', '(3 + 4)((-5) * 5)'],
      ['5 > 4 == 3 < 4', '((5 > 4) == (3 < 4))'],
      ['5 < 4 != 3 > 4', '((5 < 4) != (3 > 4))'],
      ['3 + 4 * 5 == 3 * 1 + 4 * 5', '((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))'],
      ['3 + 4 * 5 == 3 * 1 + 4 * 5', '((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))'],
      %w[true true],
      %w[false false],
      ['3 > 5 == false', '((3 > 5) == false)'],
      ['3 < 5 == true', '((3 < 5) == true)'],
      ['1 + (2 + 3) + 4', '((1 + (2 + 3)) + 4)'],
      ['(5 + 5) * 2', '((5 + 5) * 2)'],
      ['2 / (5 + 5)', '(2 / (5 + 5))'],
      ['-(5 + 5)', '(-(5 + 5))'],
      ['!(true == true)', '(!(true == true))']
    ]

    tests.each do |test|
      l = Lexer.new(test[0])
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)
      actual = program.string
      assert_equal(test[1], actual)
    end
  end

  def test_boolean
    input = 'true;'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)
    assert_equal(1, program.statements.length)
    stmt = program.statements[0]
    assert_instance_of(ExpressionStatement, stmt)
    exp = stmt.expression
    assert_instance_of(Boolean, exp)
    assert_equal(true, exp.value)
    assert_equal('true', exp.token_literal)
  end
end
