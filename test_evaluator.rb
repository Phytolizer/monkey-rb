# frozen_string_literal: true

require_relative 'evaluator'
require_relative 'lexer'
require_relative 'parser'
require 'test/unit'

## Tests for the Monkey evaluator.
class TestEvaluator < Test::Unit::TestCase
  private

  def setup_eval(input)
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    monkey_eval(program)
  end

  def check_integer_object(expected, actual)
    assert_instance_of(MonkeyInteger, actual)
    assert_equal(expected, actual.value)
  end

  def check_boolean_object(expected, actual)
    assert_same(expected, actual)
  end

  def check_null_object(actual)
    assert_same(MONKEY_NULL, actual)
  end

  public

  def test_eval_integer_expression
    test = Struct.new(:input, :expected)
    tests = [
      test.new('5', 5),
      test.new('10', 10),
      test.new('-5', -5),
      test.new('-10', -10),
      test.new('5 + 5 + 5 + 5 - 10', 10),
      test.new('2 * 2 * 2 * 2 * 2', 32),
      test.new('-50 + 100 + -50', 0),
      test.new('5 * 2 + 10', 20),
      test.new('5 + 2 * 10', 25),
      test.new('20 + 2 * -10', 0),
      test.new('50 / 2 * 2 + 10', 60),
      test.new('2 * (5 + 10)', 30),
      test.new('3 * 3 * 3 + 10', 37),
      test.new('3 * (3 * 3) + 10', 37),
      test.new('(5 + 10 * 2 + 15 / 3) * 2 + -10', 50)
    ]

    tests.each do |tt|
      evaluated = setup_eval(tt.input)
      check_integer_object(tt.expected, evaluated)
    end
  end

  def test_eval_boolean_expression
    test = Struct.new(:input, :expected)
    tests = [
      test.new('true', true),
      test.new('false', false),
      test.new('1 < 2', true),
      test.new('1 > 2', false),
      test.new('1 < 1', false),
      test.new('1 > 1', false),
      test.new('1 == 1', true),
      test.new('1 != 1', false),
      test.new('1 == 2', false),
      test.new('1 != 2', true),
      test.new('true == true', true),
      test.new('false == false', true),
      test.new('true == false', false),
      test.new('true != false', true),
      test.new('false != true', true),
      test.new('(1 < 2) == true', true),
      test.new('(1 < 2) == false', false),
      test.new('(1 > 2) == true', false),
      test.new('(1 > 2) == false', true)

    ]

    tests.each do |tt|
      evaluated = setup_eval(tt.input)
      check_boolean_object(native_bool_to_boolean_object(tt.expected), evaluated)
    end
  end

  def test_bang_operator
    test = Struct.new(:input, :expected)
    tests = [
      test.new('!true', false),
      test.new('!false', true),
      test.new('!5', false),
      test.new('!!true', true),
      test.new('!!false', false),
      test.new('!!5', true)
    ]

    tests.each do |tt|
      evaluated = setup_eval(tt.input)
      check_boolean_object(native_bool_to_boolean_object(tt.expected), evaluated)
    end
  end

  def test_if_else_expressions
    test = Struct.new(:input, :expected)
    tests = [
      test.new('if (true) { 10 }', 10),
      test.new('if (false) { 10 }', nil),
      test.new('if (1) { 10 }', 10),
      test.new('if (1 < 2) { 10 }', 10),
      test.new('if (1 > 2) { 10 }', nil),
      test.new('if (1 > 2) { 10 } else { 20 }', 20),
      test.new('if (1 < 2) { 10 } else { 20 }', 10)
    ]

    tests.each do |tt|
      evaluated = setup_eval(tt.input)
      case tt.expected
      when Integer
        check_integer_object(tt.expected, evaluated)
      else
        check_null_object(evaluated)
      end
    end
  end

  def test_return_statements
    test = Struct.new(:input, :expected)
    tests = [
      test.new('return 10;', 10),
      test.new('return 10; 9;', 10),
      test.new('return 2 * 5; 9;', 10),
      test.new('9; return 2 * 5; 9;', 10),
      test.new('
        if (10 > 1) {
          if (10 > 1) {
            return 10;
          }
          return 1;
        }
      ', 10)
    ]

    tests.each do |tt|
      evaluated = setup_eval(tt.input)
      check_integer_object(tt.expected, evaluated)
    end
  end

  def test_error_handling
    test = Struct.new(:input, :expected_message)
    tests = [
      test.new('5 + true;', 'type mismatch: INTEGER + BOOLEAN'),
      test.new('5 + true; 5;', 'type mismatch: INTEGER + BOOLEAN'),
      test.new('-true', 'unknown operator: -BOOLEAN'),
      test.new('true + false;', 'unknown operator: BOOLEAN + BOOLEAN'),
      test.new('5; true + false; 5', 'unknown operator: BOOLEAN + BOOLEAN'),
      test.new('if (10 > 1) { true + false; }', 'unknown operator: BOOLEAN + BOOLEAN'),
      test.new('
        if (10 > 1) {
          if (10 > 1) {
            return true + false;
          }
          return 1;
        }
      ', 'unknown operator: BOOLEAN + BOOLEAN')
    ]
    tests.each do |tt|
      evaluated = setup_eval(tt.input)
      assert_instance_of(MonkeyError, evaluated)
      assert_equal(tt.expected_message, evaluated.message)
    end
  end
end
