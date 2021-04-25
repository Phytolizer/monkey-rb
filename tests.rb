require 'test/unit/testsuite'
require_relative 'test_lexer'

class TS_MonkeyTests
  def self.suite
    suite = Test::Unit::TestSuite.new
    suite << TC_Lexer.suite
    suite
  end
end
