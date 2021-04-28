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

def make(opcode, operands)
  definition = DEFINITIONS[opcode]
  return [] if definition.nil?

  instruction_len = 1
  definition.operand_widths.each do |w|
    instruction_len += w
  end

  instruction = Array.new(instruction_len, nil)
  instruction[0] = opcode.ord
  offset = 1
  operands.each_with_index do |o, i|
    width = definition.operand_widths[i]
    case width
    when 2
      instruction[offset..offset + 1] = [o].pack('S>').unpack('CC')
    end
    offset += width
  end

  instruction
end

def format_instruction(definition, operands)
  operand_count = definition.operand_widths.length

  if operands.length != operand_count
    return "ERROR: operand len #{operands.length} does not match defined #{operand_count}\n"
  end

  case operand_count
  when 1
    return "#{definition.name} #{operands[0]}"
  end

  "ERROR: unhandled operand_count for #{definition.name}"
end

def format_instructions(instructions)
  out = +''
  i = 0
  while i < instructions.length
    begin
      definition = lookup(instructions[i])
    rescue ArgumentError => e
      out << "ERROR: #{e}"
      next
    end
    operands, read = read_operands(definition, instructions[i + 1...instructions.length])
    out << format("%<i>04d %<ins>s\n", i: i, ins: format_instruction(definition, operands))

    i += 1 + read
  end

  out
end

def read_operands(definition, ins)
  operands = Array.new(definition.operand_widths.length)
  offset = 0
  definition.operand_widths.each_with_index do |width, i|
    case width
    when 2
      operands[i] = read_uint16(ins[offset...offset + 2])
    end
    offset += width
  end
  [operands, offset]
end

def read_uint16(bytes)
  bytes.pack('CC').unpack1('S>')
end
