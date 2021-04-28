# frozen_string_literal: true

require 'typesafe_enum'

## opcodes
class Opcode < TypesafeEnum::Base
  new :CONSTANT
end

## An opcode definition
Definition = Struct.new(:name, :operand_widths)

DEFINITIONS = {
  Opcode::CONSTANT => Definition.new('OpConstant', [2])
}.freeze

def lookup(opcode)
  definition = DEFINITIONS[Opcode.find_by_ord(opcode)]
  raise ArgumentError, "opcode #{opcode} undefined" if definition.nil?

  definition
end

def make(opcode, _operands)
  definition = DEFINITIONS[opcode]
  return [] if definition.nil?

  instruction_len = 1
  definition.operand_widths.each do |w|
    instruction_len += w
  end

  instruction = String.unpack('CCC')
end
