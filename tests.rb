require 'test/unit/testsuite'
require_relative 'test_lexer'
require_relative 'test_parser'

class TS_MonkeyTests
  def self.suite
    suite = Test::Unit::TestSuite.new
    suite << TC_Lexer.suite
    suite << TC_Parser.suite
    suite
  end
end
