# frozen_string_literal: true

require_relative 'lexer'
require_relative 'parser'
require_relative 'token'

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

    puts program.string
  end
end

start($stdin, $stdout)
