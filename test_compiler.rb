# frozen_string_literal: true

require 'test/unit'
require_relative 'compiler'
require_relative 'code'
require_relative 'lexer'
require_relative 'object'
require_relative 'parser'

## Tests for the Monkey compiler.
class TestCompiler < Test::Unit::TestCase
  private

  CompilerTestCase = Struct.new(:input, :expected_constants, :expected_instructions)

  def parse(input)
    l = Lexer.new(input)
    p = Parser.new(l)
    p.parse_program
  end

  def concat_instructions(ins)
    ins.flatten
  end

  def check_instructions(expected, actual)
    concatted = concat_instructions(expected)
    assert_equal(format_instructions(concatted), format_instructions(actual))
  end

  def check_integer_object(expected, actual)
    assert_instance_of(MonkeyInteger, actual)
    assert_equal(expected, actual.value)
  end

  def check_constants(expected, actual)
    assert_equal(expected.length, actual.length)
    expected.each_with_index do |constant, i|
      case constant
      when Integer
        check_integer_object(constant, actual[i])
      end
    end
  end

  def run_compiler_tests(tests)
    tests.each do |tt|
      program = parse(tt.input)
      compiler = Compiler.new
      compiler.compile(program)
      bytecode = compiler.bytecode
      check_instructions(tt.expected_instructions, bytecode.instructions)
      check_constants(tt.expected_constants, bytecode.constants)
    end
  end

  public

  ## Check that compiling integer arithmetic makes sense.
  def test_integer_arithmetic
    tests = [
      CompilerTestCase.new(
        '1 + 2',
        [1, 2],
        [
          make(Opcode::CONSTANT, [0]),
          make(Opcode::CONSTANT, [1]),
          make(Opcode::ADD, []),
          make(Opcode::POP, [])
        ]
      ),
      CompilerTestCase.new(
        '1; 2',
        [1, 2],
        [
          make(Opcode::CONSTANT, [0]),
          make(Opcode::POP, []),
          make(Opcode::CONSTANT, [1]),
          make(Opcode::POP, [])
        ]
      ),
      CompilerTestCase.new(
        '1 - 2',
        [1, 2],
        [
          make(Opcode::CONSTANT, [0]),
          make(Opcode::CONSTANT, [1]),
          make(Opcode::SUB, []),
          make(Opcode::POP, [])
        ]
      ),
      CompilerTestCase.new(
        '1 * 2',
        [1, 2],
        [
          make(Opcode::CONSTANT, [0]),
          make(Opcode::CONSTANT, [1]),
          make(Opcode::MUL, []),
          make(Opcode::POP, [])
        ]
      ),
      CompilerTestCase.new(
        '2 / 1',
        [2, 1],
        [
          make(Opcode::CONSTANT, [0]),
          make(Opcode::CONSTANT, [1]),
          make(Opcode::DIV, []),
          make(Opcode::POP, [])
        ]
      )
    ]

    run_compiler_tests(tests)
  end
end
