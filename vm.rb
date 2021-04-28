# frozen_string_literal: true

STACK_SIZE = 2048

## The beating heart of Monkey, this takes compiled bytecode and executes it.
class VM
  private

  def push(obj)
    raise 'stack overflow' if @sp >= STACK_SIZE

    @stack[@sp] = obj
    @sp += 1
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
      end

      ip += 1
    end
  end
end
