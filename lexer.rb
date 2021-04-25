# frozen_string_literal: true

require_relative 'token'

def letter?(chr)
  chr.match?(/[a-zA-Z_]/)
end

def digit?(chr)
  chr.match?(/[0-9]/)
end

def whitespace?(chr)
  chr.match?(/[ \r\t\n]/)
end

## The Monkey language lexer.
## It is handwritten and very basic,
## but gets the job done.
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

  def read_identifier
    position = @position
    read_char while letter?(@ch) || digit?(@ch)
    @input[position...@position]
  end

  def read_number
    position = @position
    read_char while digit?(@ch)
    @input[position...@position]
  end

  def skip_whitespace
    read_char while whitespace?(@ch)
  end

  private :read_char, :read_identifier, :read_number, :skip_whitespace

  def next_token
    tok = nil
    skip_whitespace
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
    when '!'
      tok = make_token(:BANG, @ch)
    when '-'
      tok = make_token(:MINUS, @ch)
    when '/'
      tok = make_token(:SLASH, @ch)
    when '*'
      tok = make_token(:STAR, @ch)
    when '<'
      tok = make_token(:LT, @ch)
    when '>'
      tok = make_token(:GT, @ch)
    when "\0"
      tok = Token.new(:EOF, '')
    else
      if letter?(@ch)
        text = read_identifier
        tok = Token.new(Tokens.lookup_ident(text), text)
        return tok
      elsif digit?(@ch)
        text = read_number
        tok = Token.new(:INT, text)
        return tok
      else
        tok = make_token(:ILLEGAL, @ch)
      end
    end

    read_char

    tok
  end

  def make_token(type, chr)
    Token.new(type, chr.to_s)
  end
  private :make_token
end
