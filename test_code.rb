# frozen_string_literal: true

require_relative 'code'
require 'test/unit'

## Tests for opcodes and related.
class TestCode < Test::Unit::TestCase
  def test_make
    test = Struct.new(:op, :operands, :expected)
    tests = [
      test.new(Opcode::CONSTANT, [65_534], [Opcode::CONSTANT.ord, 255, 254])
    ]
    tests.each do |tt|
      instruction = make(tt.op, tt.operands)
      assert_equal(tt.expected.length, instruction.length)
      tt.expected.each_with_index do |b, i|
        assert_equal(b, instruction[i])
      end
    end
  end
end
