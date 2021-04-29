# frozen_string_literal: true

require 'test/unit'
require_relative 'compiler'
require_relative 'lexer'
require_relative 'parser'
require_relative 'object'
require_relative 'vm'

## Tests for the Monkey VM.
class TestVm < Test::Unit::TestCase
  private

  VmTestCase = Struct.new(:input, :expected)

  def parse(input)
    l = Lexer.new(input)
    p = Parser.new(l)
    p.parse_program
  end

  def check_integer_object(expected, actual)
    assert_instance_of(MonkeyInteger, actual)
    assert_equal(expected, actual.value)
  end

  def check_expected_object(expected, actual)
    case expected
    when Integer
      check_integer_object(expected, actual)
    end
  end

  def run_vm_tests(tests)
    tests.each do |tt|
      program = parse(tt.input)
      comp = Compiler.new
      comp.compile(program)
      vm = VM.new(comp.bytecode)
      vm.run
      stack_elem = vm.last_popped_stack_elem
      check_expected_object(tt.expected, stack_elem)
    end
  end

  public

  def test_integer_arithmetic
    tests = [
      VmTestCase.new('1', 1),
      VmTestCase.new('2', 2),
      VmTestCase.new('1 + 2', 3)
    ]
    run_vm_tests(tests)
  end
end
