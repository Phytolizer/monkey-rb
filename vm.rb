# frozen_string_literal: true

require_relative 'object'

STACK_SIZE = 2048
TRUE = MonkeyBoolean.new(true)
FALSE = MonkeyBoolean.new(false)

## The beating heart of Monkey, this takes compiled bytecode and executes it.
class VM
  private

  def push(obj)
    raise 'stack overflow' if @sp >= STACK_SIZE

    @stack[@sp] = obj
    @sp += 1
  end

  def pop
    obj = @stack[@sp - 1]
    @sp -= 1
    obj
  end

  def execute_binary_integer_operation(operator, left, right)
    case operator
    when Opcode::ADD
      result = left.value + right.value
    when Opcode::SUB
      result = left.value - right.value
    when Opcode::MUL
      result = left.value * right.value
    when Opcode::DIV
      result = left.value / right.value
    else
      raise "unknown integer operator: #{operator}"
    end

    push(MonkeyInteger.new(result))
  end

  def execute_binary_operation(operator)
    right = pop
    left = pop
    return execute_binary_integer_operation(operator, left, right) if left.type == :INTEGER && right.type == :INTEGER

    raise "unsupported types for binary operation: #{left.type} #{right.type}"
  end

  public

  ## Initialize a VM with the compiler's output.
  def initialize(bytecode)
    @instructions = bytecode.instructions
    @constants = bytecode.constants
    @stack = Array.new(STACK_SIZE)
    @sp = 0
  end

  ## What's on top of the stack?
  def stack_top
    if @sp.zero?
      nil
    else
      @stack[@sp - 1]
    end
  end

  ## What *was* on top of the stack?
  def last_popped_stack_elem
    @stack[@sp]
  end

  ## Execute the bytecode, manipulating the internal stack.
  def run
    ip = 0
    while ip < @instructions.length
      op = Opcode.find_by_ord(@instructions[ip])

      case op
      when Opcode::CONSTANT
        const_index = read_uint16(@instructions[ip + 1...ip + 3])
        ip += 2
        push(@constants[const_index])
      when Opcode::TRUE
        push(TRUE)
      when Opcode::FALSE
        push(FALSE)
      when Opcode::ADD, Opcode::SUB, Opcode::MUL, Opcode::DIV
        execute_binary_operation(op)
      when Opcode::POP
        pop
      end

      ip += 1
    end
  end
end
