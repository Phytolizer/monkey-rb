# frozen_string_literal: true

require_relative 'ast'

class Precedence
  LOWEST = 1
  EQUALITY = 2
  COMPARISON = 3
  SUM = 4
  PRODUCT = 5
  PREFIX = 6
  CALL = 7
end

class Parser
  def initialize(lexer)
    @lexer = lexer
    @cur_token = nil
    @peek_token = nil
    @errors = []
    @prefix_parse_fns = {
      IDENT: -> { parse_identifier }
    }
    @infix_parse_fns = {}

    next_token
    next_token
  end

  attr_reader :errors

  def parse_program
    statements = []

    until @cur_token.type == :EOF
      stmt = parse_statement
      statements << stmt unless stmt.nil?
      next_token
    end

    Program.new(statements)
  end

  private

  def next_token
    @cur_token = @peek_token
    @peek_token = @lexer.next_token
  end

  def cur_token_is(type)
    @cur_token.type == type
  end

  def peek_token_is(type)
    @peek_token.type == type
  end

  def expect_peek(type)
    if peek_token_is(type)
      next_token
      true
    else
      peek_error(type)
      false
    end
  end

  def peek_error(type)
    errors << "expected next token to be #{type}, got #{@cur_token.type} instead"
  end

  def parse_statement
    case @cur_token.type
    when :LET
      parse_let_statement
    when :RETURN
      parse_return_statement
    else
      parse_expression_statement
    end
  end

  def parse_let_statement
    token = @cur_token
    return nil unless expect_peek(:IDENT)

    name = Identifier.new(@cur_token, @cur_token.literal)
    return nil unless expect_peek(:ASSIGN)

    # TODO
    next_token until cur_token_is(:SEMICOLON)

    LetStatement.new(token, name, nil)
  end

  def parse_return_statement
    token = @cur_token
    next_token

    # TODO
    next_token until cur_token_is(:SEMICOLON)

    ReturnStatement.new(token, nil)
  end

  def parse_expression_statement
    token = @cur_token
    expression = parse_expression(Precedence::LOWEST)
    next_token if peek_token_is(:SEMICOLON)
    ExpressionStatement.new(token, expression)
  end

  def parse_expression(_precedence)
    prefix = @prefix_parse_fns[@cur_token.type]
    return nil if prefix.nil?

    prefix.call
  end

  def parse_identifier
    Identifier.new(@cur_token, @cur_token.literal)
  end
end
