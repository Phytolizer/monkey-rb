require 'test/unit/testsuite'
require_relative 'test_lexer'
require_relative 'test_parser'
require_relative 'test_ast'
require_relative 'test_evaluator'

class MonkeyTests
  def self.suite
    suite = Test::Unit::TestSuite.new
    suite << TestLexer.suite
    suite << TestParser.suite
    suite << TestAst.suite
    suite << TestEvaluator.suite
    suite
  end
end
