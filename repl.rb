# frozen_string_literal: true

require_relative 'lexer'
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

    loop do
      token = l.next_token
      break if token.type == :EOF

      puts "Token{#{token.type} '#{token.literal}'}"
    end
  end
end

start($stdin, $stdout)
