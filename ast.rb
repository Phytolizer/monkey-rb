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

  attr_accessor :statements

  def ==(other)
    other.is_a?(Program) && @statements == other.statements
  end
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
    result = "#{token_literal} #{@name.string} = "
    result << @value.string unless @value.nil?
    result << ';'
    result
  end

  attr_accessor :token, :name, :value

  def ==(other)
    other.is_a?(LetStatement) && @name == other.name && @value == other.value
  end
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

  attr_accessor :token, :value
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

  attr_accessor :token, :value

  def ==(other)
    other.is_a?(IntegerLiteral) && @value == other.value
  end
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

  attr_accessor :token, :operator, :right

  def ==(other)
    other.is_a?(PrefixExpression) &&
      @operator == other.operator &&
      @right == other.right
  end
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

  attr_accessor :token, :left, :operator, :right

  def ==(other)
    other.is_a?(InfixExpression) &&
      @left == other.left &&
      @right == other.right &&
      @operator == other.operator
  end
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

  attr_accessor :token, :return_value

  def ==(other)
    other.is_a?(ReturnStatement) && @return_value == other.return_value
  end
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

  attr_accessor :token, :expression

  def ==(other)
    other.is_a?(ExpressionStatement) && @expression == other.expression
  end
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

  attr_accessor :token, :value
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

  attr_accessor :token, :condition, :consequence, :alternative

  def ==(other)
    other.is_a?(IfExpression) &&
      @condition == other.condition &&
      @consequence == other.consequence &&
      @alternative == other.alternative
  end
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

  attr_accessor :token, :statements

  def ==(other)
    other.is_a?(BlockStatement) && @statements == other.statements
  end
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

  attr_accessor :token, :parameters, :body

  def ==(other)
    other.is_a?(FunctionLiteral) && @parameters == other.parameters && @body == other.body
  end
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

  attr_accessor :token, :function, :arguments
end

## A string literal.
class StringLiteral
  include Node

  def initialize(token, value)
    @token = token
    @value = value
  end

  attr_accessor :token, :value

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

  attr_accessor :token, :elements

  def string
    "[#{@elements.map(&:string).join(', ')}]"
  end

  def ==(other)
    other.is_a?(ArrayLiteral) && @elements == other.elements
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

  attr_accessor :token, :left, :index

  def string
    "(#{@left.string}[#{@index.string}])"
  end

  def ==(other)
    other.is_a?(IndexExpression) && @left == other.left && @index == other.index
  end
end

## A hash literal. Hashes are like Ruby's Hash.
class HashLiteral
  include Node

  def initialize(token, pairs)
    @token = token
    @pairs = pairs
  end

  attr_accessor :token, :pairs

  def string
    pairs = []
    @pairs.each do |k, v|
      pairs << "#{k.string}:#{v.string}"
    end
    "{#{pairs.join(', ')}}"
  end
end

def modify(node, modifier)
  case node
  when Program, BlockStatement
    node.statements.each_with_index do |statement, i|
      node.statements[i] = modify(statement, modifier)
    end
  when ReturnStatement
    node.return_value = modify(node.return_value, modifier)
  when LetStatement
    node.value = modify(node.value, modifier)
  when ExpressionStatement
    node.expression = modify(node.expression, modifier)
  when InfixExpression
    node.left = modify(node.left, modifier)
    node.right = modify(node.right, modifier)
  when PrefixExpression
    node.right = modify(node.right, modifier)
  when IndexExpression
    node.left = modify(node.left, modifier)
    node.index = modify(node.index, modifier)
  when IfExpression
    node.condition = modify(node.condition, modifier)
    node.consequence = modify(node.consequence, modifier)
    node.alternative = modify(node.alternative, modifier) unless node.alternative.nil?
  when FunctionLiteral
    node.parameters.each_with_index do |param, i|
      node.parameters[i] = modify(param, modifier)
    end
    node.body = modify(node.body, modifier)
  when ArrayLiteral
    node.elements.each_with_index do |element, i|
      node.elements[i] = modify(element, modifier)
    end
  when HashLiteral
    new_pairs = {}
    node.pairs.each do |key, val|
      new_key = modify(key, modifier)
      new_val = modify(val, modifier)
      new_pairs[new_key] = new_val
    end
    node.pairs = new_pairs
  end

  modifier.call(node)
end
