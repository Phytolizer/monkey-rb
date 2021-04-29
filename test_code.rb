# frozen_string_literal: true

require_relative 'code'
require 'test/unit'

## Tests for opcodes and instructions.
class TestCode < Test::Unit::TestCase
  ## Check that the `make` method isn't misbehaving.
  def test_make
    test = Struct.new(:op, :operands, :expected)
    tests = [
      test.new(Opcode::CONSTANT, [65_534], [Opcode::CONSTANT.ord, 255, 254]),
      test.new(Opcode::ADD, [], [Opcode::ADD.ord])
    ]
    tests.each do |tt|
      instruction = make(tt.op, tt.operands)
      assert_equal(tt.expected, instruction)
    end
  end

  ## Check that instructions can be converted to human-readable form.
  def test_instructions_string
    instructions = [
      make(Opcode::ADD, []),
      make(Opcode::CONSTANT, [2]),
      make(Opcode::CONSTANT, [65_535])
    ]

    expected = <<~EXP
      0000 OpAdd
      0001 OpConstant 2
      0004 OpConstant 65535
    EXP
    concatted = instructions.flatten
    assert_equal(expected, format_instructions(concatted))
  end

  ## Check that reading operands from a packed instruction succeeds.
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
