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

PRECEDENCES = {
  EQ: Precedence::EQUALITY,
  NOT_EQ: Precedence::EQUALITY,
  LT: Precedence::COMPARISON,
  GT: Precedence::COMPARISON,
  PLUS: Precedence::SUM,
  MINUS: Precedence::SUM,
  STAR: Precedence::PRODUCT,
  SLASH: Precedence::PRODUCT
}

class Parser
  def initialize(lexer)
    @lexer = lexer
    @cur_token = nil
    @peek_token = nil
    @errors = []
    @prefix_parse_fns = {
      IDENT: -> { parse_identifier },
      INT: -> { parse_integer_literal },
      BANG: -> { parse_prefix_expression },
      MINUS: -> { parse_prefix_expression },
      TRUE: -> { parse_boolean },
      FALSE: -> { parse_boolean },
      LPAREN: -> { parse_grouped_expression },
      IF: -> { parse_if_expression },
      FUNCTION: -> { parse_function_literal }
    }
    @infix_parse_fns = {
      PLUS: ->(x) { parse_infix_expression(x) },
      MINUS: ->(x) { parse_infix_expression(x) },
      STAR: ->(x) { parse_infix_expression(x) },
      SLASH: ->(x) { parse_infix_expression(x) },
      LT: ->(x) { parse_infix_expression(x) },
      GT: ->(x) { parse_infix_expression(x) },
      EQ: ->(x) { parse_infix_expression(x) },
      NOT_EQ: ->(x) { parse_infix_expression(x) }
    }

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

  def cur_precedence
    val = PRECEDENCES[@cur_token.type]
    return val unless val.nil?

    Precedence::LOWEST
  end

  def peek_precedence
    val = PRECEDENCES[@peek_token.type]
    return val unless val.nil?

    Precedence::LOWEST
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

  def no_prefix_parse_fn_error(type)
    errors << "no prefix parse function for #{type} found"
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

  def parse_expression(precedence)
    prefix = @prefix_parse_fns[@cur_token.type]
    if prefix.nil?
      no_prefix_parse_fn_error(@cur_token.type)
      return nil
    end

    left_exp = prefix.call

    while !peek_token_is(:SEMICOLON) && precedence < peek_precedence
      infix = @infix_parse_fns[@peek_token.type]
      return left_exp if infix.nil?

      next_token
      left_exp = infix.call(left_exp)
    end

    left_exp
  end

  def parse_identifier
    Identifier.new(@cur_token, @cur_token.literal)
  end

  def parse_integer_literal
    IntegerLiteral.new(@cur_token, @cur_token.literal.to_i)
  end

  def parse_prefix_expression
    token = @cur_token
    operator = @cur_token.literal
    next_token
    right = parse_expression(Precedence::PREFIX)

    PrefixExpression.new(token, operator, right)
  end

  def parse_infix_expression(left)
    token = @cur_token
    operator = @cur_token.literal
    precedence = cur_precedence
    next_token
    right = parse_expression(precedence)
    InfixExpression.new(token, left, operator, right)
  end

  def parse_boolean
    Boolean.new(@cur_token, cur_token_is(:TRUE))
  end

  def parse_grouped_expression
    next_token
    exp = parse_expression(Precedence::LOWEST)
    return nil unless expect_peek(:RPAREN)

    exp
  end

  def parse_if_expression
    token = @cur_token
    return nil unless expect_peek(:LPAREN)

    next_token
    condition = parse_expression(Precedence::LOWEST)
    return nil unless expect_peek(:RPAREN)
    return nil unless expect_peek(:LBRACE)

    consequence = parse_block_statement
    alternative = nil
    if peek_token_is(:ELSE)
      next_token
      return nil unless expect_peek(:LBRACE)

      alternative = parse_block_statement
    end

    IfExpression.new(token, condition, consequence, alternative)
  end

  def parse_block_statement
    token = @cur_token
    statements = []
    next_token
    while !cur_token_is(:RBRACE) && !cur_token_is(:EOF)
      stmt = parse_statement
      statements << stmt unless stmt.nil?
      next_token
    end

    BlockStatement.new(token, statements)
  end

  def parse_function_literal
    token = @cur_token
    return nil unless expect_peek(:LPAREN)

    parameters = parse_function_parameters
    return nil unless expect_peek(:LBRACE)

    body = parse_block_statement
    FunctionLiteral.new(token, parameters, body)
  end

  def parse_function_parameters
    identifiers = []
    if peek_token_is(:RPAREN)
      next_token
      return identifiers
    end

    next_token
    ident = Identifier.new(@cur_token, @cur_token.literal)
    identifiers << ident

    while peek_token_is(:COMMA)
      next_token
      next_token
      ident = Identifier.new(@cur_token, @cur_token.literal)
      identifiers << ident
    end
    return nil unless expect_peek(:RPAREN)

    identifiers
  end
end
