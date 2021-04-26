# frozen_string_literal: true

require_relative 'ast'
require_relative 'object'

MONKEY_TRUE = MonkeyBoolean.new(true)
MONKEY_FALSE = MonkeyBoolean.new(false)
MONKEY_NULL = MonkeyNull.new

def truthy?(value)
  case value
  when MONKEY_NULL, MONKEY_FALSE
    false
  else
    true
  end
end

def eval_program(program)
  result = nil
  program.statements.each do |stmt|
    result = monkey_eval(stmt)
    case result
    when ReturnValue
      return result.value
    when MonkeyError
      return result
    end
  end
  result
end

def eval_block_statement(block)
  result = nil
  block.statements.each do |stmt|
    result = monkey_eval(stmt)

    return result if !result.nil? && %i[RETURN_VALUE ERROR].include?(result.type)
  end
  result
end

def eval_bang_operator_expression(right)
  case right
  when MONKEY_FALSE, MONKEY_NULL
    MONKEY_TRUE
  else
    MONKEY_FALSE
  end
end

def eval_minus_prefix_operator_expression(right)
  return MonkeyError.new("unknown operator: -#{right.type}") if right.type != :INTEGER

  value = right.value
  MonkeyInteger.new(-value)
end

def eval_prefix_expression(operator, right)
  case operator
  when '!'
    eval_bang_operator_expression(right)
  when '-'
    eval_minus_prefix_operator_expression(right)
  else
    MonkeyError.new("unknown operator: #{operator}#{right.type}")
  end
end

def eval_integer_infix_expression(operator, left, right)
  case operator
  when '+'
    MonkeyInteger.new(left.value + right.value)
  when '-'
    MonkeyInteger.new(left.value - right.value)
  when '*'
    MonkeyInteger.new(left.value * right.value)
  when '/'
    MonkeyInteger.new(left.value / right.value)
  when '<'
    native_bool_to_boolean_object(left.value < right.value)
  when '>'
    native_bool_to_boolean_object(left.value > right.value)
  when '=='
    native_bool_to_boolean_object(left.value == right.value)
  when '!='
    native_bool_to_boolean_object(left.value != right.value)
  else
    MonkeyError.new("unknown operator: #{left.type} #{operator} #{right.type}")
  end
end

def eval_infix_expression(operator, left, right)
  if left.type == :INTEGER && right.type == :INTEGER
    eval_integer_infix_expression(operator, left, right)
  elsif operator == '=='
    native_bool_to_boolean_object(left == right)
  elsif operator == '!='
    native_bool_to_boolean_object(left != right)
  elsif left.type != right.type
    MonkeyError.new("type mismatch: #{left.type} #{operator} #{right.type}")
  else
    MonkeyError.new("unknown operator: #{left.type} #{operator} #{right.type}")
  end
end

def monkey_eval(node)
  case node
  when Program
    eval_program(node)
  when BlockStatement
    eval_block_statement(node)
  when ReturnStatement
    val = monkey_eval(node.return_value)
    ReturnValue.new(val)
  when ExpressionStatement
    monkey_eval(node.expression)
  when IntegerLiteral
    MonkeyInteger.new(node.value)
  when Boolean
    native_bool_to_boolean_object(node.value)
  when PrefixExpression
    right = monkey_eval(node.right)
    eval_prefix_expression(node.operator, right)
  when InfixExpression
    left = monkey_eval(node.left)
    right = monkey_eval(node.right)
    eval_infix_expression(node.operator, left, right)
  when IfExpression
    condition = monkey_eval(node.condition)
    if truthy?(condition)
      monkey_eval(node.consequence)
    elsif !node.alternative.nil?
      monkey_eval(node.alternative)
    else
      MONKEY_NULL
    end
  end
end

def native_bool_to_boolean_object(value)
  if value
    MONKEY_TRUE
  else
    MONKEY_FALSE
  end
end
