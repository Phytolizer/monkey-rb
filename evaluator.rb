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

def error?(value)
  !value.nil? && value.type == :ERROR
end

def eval_program(program, env)
  result = nil
  program.statements.each do |stmt|
    result = monkey_eval(stmt, env)
    case result
    when ReturnValue
      return result.value
    when MonkeyError
      return result
    end
  end
  result
end

def eval_block_statement(block, env)
  result = nil
  block.statements.each do |stmt|
    result = monkey_eval(stmt, env)

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

def eval_identifier(node, env)
  val = env.get(node.value)
  if val.nil?
    MonkeyError.new("identifier not found: #{node.value}")
  else
    val
  end
end

def monkey_eval(node, env)
  case node
  when Program
    eval_program(node, env)
  when BlockStatement
    eval_block_statement(node, env)
  when ReturnStatement
    val = monkey_eval(node.return_value, env)
    return val if error?(val)

    ReturnValue.new(val)
  when LetStatement
    val = monkey_eval(node.value, env)
    return val if error?(val)

    env.set(node.name.value, val)
  when ExpressionStatement
    monkey_eval(node.expression, env)
  when IntegerLiteral
    MonkeyInteger.new(node.value)
  when Boolean
    native_bool_to_boolean_object(node.value)
  when PrefixExpression
    right = monkey_eval(node.right, env)
    return right if error?(right)

    eval_prefix_expression(node.operator, right)
  when InfixExpression
    left = monkey_eval(node.left, env)
    return left if error?(left)

    right = monkey_eval(node.right, env)
    return right if error?(right)

    eval_infix_expression(node.operator, left, right)
  when IfExpression
    condition = monkey_eval(node.condition, env)
    return condition if error?(condition)

    if truthy?(condition)
      monkey_eval(node.consequence, env)
    elsif !node.alternative.nil?
      monkey_eval(node.alternative, env)
    else
      MONKEY_NULL
    end
  when Identifier
    eval_identifier(node, env)
  end
end

def native_bool_to_boolean_object(value)
  if value
    MONKEY_TRUE
  else
    MONKEY_FALSE
  end
end
