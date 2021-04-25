# frozen_string_literal: true

require_relative 'token'

class Lexer
  def initialize(input)
    @input = input
    @position = 0
    @read_position = 0
    @ch = "\0"
    read_char
  end

  def read_char
    @ch = if @read_position >= @input.length
            "\0"
          else
            @input[@read_position]
          end
    @position = @read_position
    @read_position += 1
  end

  private :read_char

  def next_token
    tok = nil
    case @ch
    when '='
      tok = make_token(:ASSIGN, @ch)
    when ';'
      tok = make_token(:SEMICOLON, @ch)
    when ','
      tok = make_token(:COMMA, @ch)
    when '+'
      tok = make_token(:PLUS, @ch)
    when '('
      tok = make_token(:LPAREN, @ch)
    when ')'
      tok = make_token(:RPAREN, @ch)
    when '{'
      tok = make_token(:LBRACE, @ch)
    when '}'
      tok = make_token(:RBRACE, @ch)
    when "\0"
      tok = Token.new(:EOF, '')
    end

    read_char

    tok
  end

  def make_token(type, chr)
    Token.new(type, chr.to_s)
  end
  private :make_token
end
