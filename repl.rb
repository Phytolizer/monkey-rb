# frozen_string_literal: true

require_relative 'compiler'
require_relative 'evaluator'
require_relative 'lexer'
require_relative 'parser'
require_relative 'token'
require_relative 'vm'

PROMPT = '>> '

def start(input, output)
  loop do
    output.write(PROMPT)
    begin
      line = input.readline
    rescue EOFError
      puts
      break
    end

    l = Lexer.new(line)
    p = Parser.new(l)
    program = p.parse_program
    p.errors.each { |error| warn error }
    next unless p.errors.empty?

    comp = Compiler.new
    begin
      comp.compile(program)
    rescue RuntimeError => e
      puts "compilation failed: #{e}"
      next
    end

    vm = VM.new(comp.bytecode)
    begin
      vm.run
    rescue RuntimeError => e
      puts "bytecode execution failed: #{e}"
      next
    end

    last_popped = vm.last_popped_stack_elem
    puts last_popped.inspect
  end
end

start($stdin, $stdout)
