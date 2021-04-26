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

  public

  def test_eval_integer_expression
    tests = [
      ['5', 5],
      ['10', 10]
    ]

    tests.each do |test|
      evaluated = setup_eval(test[0])
      check_integer_object(test[1], evaluated)
    end
  end
end
