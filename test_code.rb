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
      assert_equal(tt.expected, instruction)
    end
  end

  def test_instructions_string
    instructions = [
      make(Opcode::CONSTANT, [1]),
      make(Opcode::CONSTANT, [2]),
      make(Opcode::CONSTANT, [65_535])
    ]

    expected = <<~EXP
      0000 OpConstant 1
      0003 OpConstant 2
      0006 OpConstant 65535
    EXP
    concatted = instructions.flatten
    assert_equal(expected, format_instructions(concatted))
  end

  def test_read_operands
    test = Struct.new(:op, :operands, :bytes_read)
    tests = [
      test.new(Opcode::CONSTANT, [65_535], 2)
    ]
    tests.each do |tt|
      instruction = make(tt.op, tt.operands)
      definition = lookup(tt.op.ord)
      assert_not_nil(definition)
      operands_read, n = read_operands(definition, instruction[1...instruction.length])
      assert_equal(tt.bytes_read, n)
      assert_equal(tt.operands, operands_read)
    end
  end
end
