# frozen_string_literal: true

## A single AST node.
## The main use of this module is to ease
## implementation of token_literal, as it is typically repeated.
module Node
  def token_literal
    @token.literal
  end

  def string
    raise NotImplementedError, "please implement me :'("
  end
end

## The entire program.
## In other words, this is the root of the AST.
class Program
  include Node

  def initialize(statements)
    @statements = statements
  end

  def token_literal
    if @statements.empty?
      ''
    else
      @statements[0].token_literal
    end
  end

  def string
    @statements.map(&:string).join
  end

  attr_reader :statements
end

## A 'let' statement:
## `let x = 5;`
class LetStatement
  include Node

  def initialize(token, name, value)
    @token = token
    @name = name
    @value = value
  end

  def string
    result = +"#{token_literal} #{@name.string} = "
    result << @value.string unless @value.nil?
    result << ';'
    result
  end

  attr_reader :token, :name, :value
end

## An identifier. Valid identifiers in Monkey
## begin with a letter or underscore, and contain letters, digits, or underscores.
class Identifier
  include Node

  def initialize(token, value)
    @token = token
    @value = value
  end

  def string
    token_literal
  end

  attr_reader :token, :value
end

## An integer literal. These can be of any length.
class IntegerLiteral
  include Node

  def initialize(token, value)
    @token = token
    @value = value
  end

  def string
    token_literal
  end

  attr_reader :token, :value
end

## A prefix expression.
## Valid prefix operators are ! and -.
class PrefixExpression
  include Node

  def initialize(token, operator, right)
    @token = token
    @operator = operator
    @right = right
  end

  def string
    "(#{@operator}#{@right.string})"
  end

  attr_reader :token, :operator, :right
end

## An infix expression.
## Infix expressions are characterized by their operator,
## but this system is also used for call expressions.
## Valid operator tokens: +, -, *, /, <, >, ==, !=, (
class InfixExpression
  include Node

  def initialize(token, left, operator, right)
    @token = token
    @left = left
    @operator = operator
    @right = right
  end

  def string
    "(#{@left.string} #{@operator} #{@right.string})"
  end

  attr_reader :token, :left, :operator, :right
end

## A return statement, e.g. from a function.
## `return 12 + 6;`
class ReturnStatement
  include Node

  def initialize(token, return_value)
    @token = token
    @return_value = return_value
  end

  def string
    result = "#{token_literal} "
    result << return_value.string unless @return_value.nil?
    result << ';'
  end

  attr_reader :token, :return_value
end

## A statement which consists of only an expression.
class ExpressionStatement
  include Node

  def initialize(token, expression)
    @token = token
    @expression = expression
  end

  def string
    if @expression.nil?
      ''
    else
      @expression.string
    end
  end

  attr_reader :token, :expression
end

## A boolean literal. Can only be `true` or `false`.
class Boolean
  include Node

  def initialize(token, value)
    @token = token
    @value = value
  end

  def string
    token_literal
  end

  attr_reader :token, :value
end

## An if expression. Consists of a condition, consequence, and an optional alternative.
class IfExpression
  include Node

  def initialize(token, condition, consequence, alternative)
    @token = token
    @condition = condition
    @consequence = consequence
    @alternative = alternative
  end

  def string
    out = "#{token_literal}#{@condition.string} #{@consequence.string}"
    out << " else #{@alternative.string}" unless @alternative.nil?
    out
  end

  attr_reader :token, :condition, :consequence, :alternative
end

## A block statement.
## Typically used as the contents of an if expression or function literal.
class BlockStatement
  include Node

  def initialize(token, statements)
    @token = token
    @statements = statements
  end

  def string
    @statements.map(&:string).join
  end

  attr_reader :token, :statements
end

## A function definition.
## Functions are nameless unless used in a `let` statement.
class FunctionLiteral
  include Node

  def initialize(token, parameters, body)
    @token = token
    @parameters = parameters
    @body = body
  end

  def string
    "#{token_literal}(#{@parameters.map(&:string).join(', ')}) #{@body.string}"
  end

  attr_reader :token, :parameters, :body
end

## A call expression.
## The function is an expression
## because function literals are valid in that position.
class CallExpression
  include Node

  def initialize(token, function, arguments)
    @token = token
    @function = function
    @arguments = arguments
  end

  def string
    "#{@function.string}(#{@arguments.map(&:string).join(', ')})"
  end

  attr_reader :token, :function, :arguments
end

## A string literal.
class StringLiteral
  include Node

  def initialize(token, value)
    @token = token
    @value = value
  end

  attr_reader :token, :value

  def string
    token_literal
  end
end

## An array literal.
class ArrayLiteral
  include Node

  def initialize(token, elements)
    @token = token
    @elements = elements
  end

  attr_reader :token, :elements

  def string
    "[#{@elements.map(&:string).join(', ')}]"
  end
end

## Indexing an array.
class IndexExpression
  include Node

  def initialize(token, left, index)
    @token = token
    @left = left
    @index = index
  end

  attr_reader :token, :left, :index

  def string
    "(#{@left.string}[#{@index.string}])"
  end
end

## A hash literal. Hashes are like Ruby's Hash.
class HashLiteral
  include Node

  def initialize(token, pairs)
    @token = token
    @pairs = pairs
  end

  attr_reader :token, :pairs

  def string
    pairs = []
    @pairs.each do |k, v|
      pairs << "#{k.string}:#{v.string}"
    end
    "{#{pairs.join(', ')}}"
  end
end
