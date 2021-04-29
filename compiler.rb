# frozen_string_literal: true

require_relative 'ast'
require_relative 'code'
require_relative 'object'

Bytecode = Struct.new(:instructions, :constants)

## The Monkey compiler. Emits bytecode for the Monkey VM.
class Compiler
  private

  def add_constant(obj)
    @constants << obj
    @constants.length - 1
  end

  def emit(opcode, operands)
    ins = make(opcode, operands)
    add_instruction(ins)
  end

  def add_instruction(ins)
    pos_new_instruction = @instructions.length
    @instructions.concat(ins)
    pos_new_instruction
  end

  public

  def initialize
    @instructions = []
    @constants = []
  end

  def compile(node)
    case node
    when Program
      node.statements.each do |stmt|
        compile(stmt)
      end
    when ExpressionStatement
      compile(node.expression)
      emit(Opcode::POP, [])
    when InfixExpression
      compile(node.left)
      compile(node.right)
      case node.operator
      when '+'
        emit(Opcode::ADD, [])
      when '-'
        emit(Opcode::SUB, [])
      when '*'
        emit(Opcode::MUL, [])
      when '/'
        emit(Opcode::DIV, [])
      else
        raise "unknown operator #{node.operator}"
      end
    when IntegerLiteral
      integer = MonkeyInteger.new(node.value)
      emit(Opcode::CONSTANT, [add_constant(integer)])
    when Boolean
      if node.value
        emit(Opcode::TRUE, [])
      else
        emit(Opcode::FALSE, [])
      end
    end
  end

  def bytecode
    Bytecode.new(@instructions, @constants)
  end
end
