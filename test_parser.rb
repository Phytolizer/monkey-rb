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
    assert_equal(expected[0], actual.name.value)
    assert_equal(expected[0], actual.name.token_literal)
    check_literal_expression(expected[1], actual.value)
  end

  def check_parser_errors(parser)
    parser.errors.each do |error|
      warn "parser error: #{error}"
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

  def check_infix_expression(left, operator, right, actual)
    assert_instance_of(InfixExpression, actual)
    check_literal_expression(left, actual.left)
    assert_equal(operator, actual.operator)
    check_literal_expression(right, actual.right)
  end

  public

  def test_let_statement
    tests = [
      ['let x = 5;', 'x', 5],
      ['let y = true;', 'y', true],
      ['let foobar = y;', 'foobar', 'y']
    ]

    tests.each do |test|
      l = Lexer.new(test[0])
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)

      assert_equal(1, program.statements.length)
      stmt = program.statements[0]
      check_let_statement(test[1..2], stmt)
    end
  end

  def test_return_statement
    tests = [
      ['return 5;', 5],
      ['return true;', true],
      ['return y;', 'y']
    ]

    tests.each do |test|
      l = Lexer.new(test[0])
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)
      assert_equal(1, program.statements.length)
      stmt = program.statements[0]
      assert_instance_of(ReturnStatement, stmt)
      assert_equal('return', stmt.token_literal)
      check_literal_expression(test[1], stmt.return_value)
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
      ['!(true == true)', '(!(true == true))'],
      ['a + add(b * c) + d', '((a + add((b * c))) + d)'],
      ['add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))', 'add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))'],
      ['add(a + b + c * d / f + g)', 'add((((a + b) + ((c * d) / f)) + g))'],
      ['a * [1, 2, 3, 4][b * c] * d', '((a * ([1, 2, 3, 4][(b * c)])) * d)'],
      ['add(a * b[2], b[1], 2 * [1, 2][1])', 'add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))']

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

  def test_if_expression
    input = 'if (x < y) { x }'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)
    assert_equal(1, program.statements.length)
    stmt = program.statements[0]
    assert_instance_of(ExpressionStatement, stmt)
    exp = stmt.expression
    assert_instance_of(IfExpression, exp)
    check_infix_expression('x', '<', 'y', exp.condition)
    assert_equal(exp.consequence.statements.length, 1)
    consequence = exp.consequence.statements[0]
    assert_instance_of(ExpressionStatement, consequence)
    check_identifier('x', consequence.expression)
    assert_nil(exp.alternative)
  end

  def test_if_else_expression
    input = 'if (x < y) { x } else { y }'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)
    assert_equal(1, program.statements.length)
    stmt = program.statements[0]
    assert_instance_of(ExpressionStatement, stmt)
    exp = stmt.expression
    assert_instance_of(IfExpression, exp)
    check_infix_expression('x', '<', 'y', exp.condition)
    assert_equal(exp.consequence.statements.length, 1)
    consequence = exp.consequence.statements[0]
    assert_instance_of(ExpressionStatement, consequence)
    check_identifier('x', consequence.expression)
    assert_not_nil(exp.alternative)
    assert_equal(exp.alternative.statements.length, 1)
    alternative = exp.alternative.statements[0]
    assert_instance_of(ExpressionStatement, alternative)
    check_identifier('y', alternative.expression)
  end

  def test_function_literal
    input = 'fn(x, y) { x + y; }'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)
    assert_equal(1, program.statements.length)
    stmt = program.statements[0]
    assert_instance_of(ExpressionStatement, stmt)
    function = stmt.expression
    assert_instance_of(FunctionLiteral, function)
    assert_equal(2, function.parameters.length)
    check_literal_expression('x', function.parameters[0])
    check_literal_expression('y', function.parameters[1])
    assert_equal(1, function.body.statements.length)
    body = function.body.statements[0]
    assert_instance_of(ExpressionStatement, body)
    check_infix_expression('x', '+', 'y', body.expression)
  end

  def test_function_parameters
    tests = [
      ['fn() {};', []],
      ['fn(x) {};', ['x']],
      ['fn(x, y, z) {};', %w[x y z]]
    ]
    tests.each do |test|
      l = Lexer.new(test[0])
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)
      stmt = program.statements[0]
      assert_instance_of(ExpressionStatement, stmt)
      function = stmt.expression
      assert_instance_of(FunctionLiteral, function)
      assert_equal(test[1].length, function.parameters.length)
      test[1].each_with_index do |ident, i|
        check_literal_expression(ident, function.parameters[i])
      end
    end
  end

  def test_call_expression
    input = 'add(1, 2 * 3, 4 + 5)'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)
    assert_equal(1, program.statements.length)
    stmt = program.statements[0]
    assert_instance_of(ExpressionStatement, stmt)
    exp = stmt.expression
    assert_instance_of(CallExpression, exp)
    check_identifier('add', exp.function)
    assert_equal(3, exp.arguments.length)
    check_literal_expression(1, exp.arguments[0])
    check_infix_expression(2, '*', 3, exp.arguments[1])
    check_infix_expression(4, '+', 5, exp.arguments[2])
  end

  def test_string_literal_expression
    input = '"hello world";'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)
    stmt = program.statements[0]
    assert_instance_of(ExpressionStatement, stmt)
    literal = stmt.expression
    assert_instance_of(StringLiteral, literal)
    assert_equal('hello world', literal.value)
  end

  def test_empty_array_literal
    input = '[]'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)
    stmt = program.statements[0]
    assert_instance_of(ExpressionStatement, stmt)
    array = stmt.expression
    assert_instance_of(ArrayLiteral, array)
    assert_equal(0, array.elements.length)
  end

  def test_array_literals
    input = '[1, 2 * 2, 3 + 3]'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)
    stmt = program.statements[0]
    assert_instance_of(ExpressionStatement, stmt)
    array = stmt.expression
    assert_instance_of(ArrayLiteral, array)
    assert_equal(3, array.elements.length)
    check_integer_literal(1, array.elements[0])
    check_infix_expression(2, '*', 2, array.elements[1])
    check_infix_expression(3, '+', 3, array.elements[2])
  end

  def test_index_expressions
    input = 'myArray[1 + 1]'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)
    stmt = program.statements[0]
    assert_instance_of(ExpressionStatement, stmt)
    exp = stmt.expression
    assert_instance_of(IndexExpression, exp)
    check_identifier('myArray', exp.left)
    check_infix_expression(1, '+', 1, exp.index)
  end
end
