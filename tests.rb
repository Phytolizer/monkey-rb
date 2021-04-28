# frozen_string_literal: true

require 'test/unit/testsuite'
require_relative 'test_ast'
require_relative 'test_code'
require_relative 'test_evaluator'
require_relative 'test_lexer'
require_relative 'test_object'
require_relative 'test_parser'

## Tests for the Monkey language.
class MonkeyTests
  def self.suite
    suite = Test::Unit::TestSuite.new
    suite << TestAst.suite
    suite << TestCode.suite
    suite << TestEvaluator.suite
    suite << TestLexer.suite
    suite << TestObject.suite
    suite << TestParser.suite
    suite
  end
end
