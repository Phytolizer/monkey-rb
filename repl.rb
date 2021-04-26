# frozen_string_literal: true

require_relative 'evaluator'
require_relative 'lexer'
require_relative 'parser'
require_relative 'token'

PROMPT = '>> '

def start(input, output)
  env = Environment.new
  macro_env = Environment.new
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

    define_macros(program, macro_env)
    expanded = expand_macros(program, macro_env)
    evaluated = monkey_eval(expanded, env)
    output.write("#{evaluated.inspect}\n") unless evaluated.nil?
  end
end

start($stdin, $stdout)
