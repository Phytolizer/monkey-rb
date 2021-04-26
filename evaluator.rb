# frozen_string_literal: true

require_relative 'ast'
require_relative 'object'

MONKEY_TRUE = MonkeyBoolean.new(true)
MONKEY_FALSE = MonkeyBoolean.new(false)
MONKEY_NULL = MonkeyNull.new

BUILTINS = {
  'len' => MonkeyBuiltin.new(
    lambda do |args|
      return MonkeyError.new("wrong number of arguments. got=#{args.length}, want=1") if args.length != 1

      case args[0]
      when MonkeyString
        MonkeyInteger.new(args[0].value.length)
      when MonkeyArray
        MonkeyInteger.new(args[0].elements.length)
      else
        MonkeyError.new("argument to `len` not supported, got #{args[0].type}")
      end
    end
  ),
  'first' => MonkeyBuiltin.new(
    lambda do |args|
      return MonkeyError.new("wrong number of arguments. got=#{args.length}, want=1") if args.length != 1
      return MonkeyError.new("argument to `first` must be ARRAY, got #{args[0].type}") if args[0].type != :ARRAY

      arr = args[0]
      if arr.elements.length.positive?
        arr.elements[0]
      else
        MONKEY_NULL
      end
    end
  ),
  'last' => MonkeyBuiltin.new(
    lambda do |args|
      return MonkeyError.new("wrong number of arguments. got=#{args.length}, want=1") if args.length != 1
      return MonkeyError.new("argument to `last` must be ARRAY, got #{args[0].type}") if args[0].type != :ARRAY

      arr = args[0]
      if arr.elements.length.positive?
        arr.elements[arr.elements.length - 1]
      else
        MONKEY_NULL
      end
    end
  ),
  'rest' => MonkeyBuiltin.new(
    lambda do |args|
      return MonkeyError.new("wrong number of arguments. got=#{args.length}, want=1") if args.length != 1
      return MonkeyError.new("argument to `last` must be ARRAY, got #{args[0].type}") if args[0].type != :ARRAY

      arr = args[0]
      length = arr.elements.length
      if length.positive?
        new_elements = arr.elements[1...length]
        return MonkeyArray.new(new_elements)
      end
      MONKEY_NULL
    end
  ),
  'push' => MonkeyBuiltin.new(
    lambda do |args|
      return MonkeyError.new("wrong number of arguments. got=#{args.length}, want=2") if args.length != 2
      return MonkeyError.new("argument to `last` must be ARRAY, got #{args[0].type}") if args[0].type != :ARRAY

      arr = args[0]
      new_elements = arr.elements.dup
      new_elements << args[1]
      MonkeyArray.new(new_elements)
    end
  ),
  'puts' => MonkeyBuiltin.new(
    lambda do |args|
      args.each do |arg|
        puts arg.inspect
      end

      MONKEY_NULL
    end
  )
}.freeze

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

def eval_string_infix_expression(operator, left, right)
  return MonkeyError.new("unknown operator: #{left.type} #{operator} #{right.type}") if operator != '+'

  MonkeyString.new(left.value + right.value)
end

def eval_infix_expression(operator, left, right)
  if left.type == :INTEGER && right.type == :INTEGER
    eval_integer_infix_expression(operator, left, right)
  elsif left.type == :STRING && right.type == :STRING
    eval_string_infix_expression(operator, left, right)
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
  return val unless val.nil?

  builtin = BUILTINS[node.value]
  return builtin unless builtin.nil?

  MonkeyError.new("identifier not found: #{node.value}")
end

def eval_expressions(exps, env)
  result = []
  exps.each do |e|
    evaluated = monkey_eval(e, env)
    return [evaluated] if error?(evaluated)

    result << evaluated
  end
  result
end

def apply_function(func, args)
  case func
  when Function
    extended_env = extend_function_env(func, args)
    evaluated = monkey_eval(func.body, extended_env)
    unwrap_return_value(evaluated)
  when MonkeyBuiltin
    func.fn.call(args)
  else
    MonkeyError.new("not a function: #{func.type}")
  end
end

def extend_function_env(func, args)
  env = Environment.new(func.env)
  func.parameters.each_with_index do |param, param_idx|
    env.set(param.value, args[param_idx])
  end
  env
end

def unwrap_return_value(obj)
  return obj.value if obj.is_a?(ReturnValue)

  obj
end

def eval_index_expression(left, index)
  if left.type == :ARRAY && index.type == :INTEGER
    eval_array_index_expression(left, index)
  elsif left.type == :HASH
    eval_hash_index_expression(left, index)
  else
    MonkeyError.new("index operator not supported: #{left.type}")
  end
end

def eval_hash_index_expression(left, index)
  return MonkeyError.new("unusable as hash key: #{index.type}") unless index.is_a?(Hashable)

  pair = left.pairs[index.hash_key]
  return MONKEY_NULL if pair.nil?

  pair.value
end

def eval_array_index_expression(array, index)
  max = array.elements.length - 1
  return MONKEY_NULL if index.value.negative? || index.value > max

  array.elements[index.value]
end

def eval_hash_literal(node, env)
  pairs = {}
  node.pairs.each do |key_node, value_node|
    key = monkey_eval(key_node, env)
    return key if error?(key)
    return MonkeyError.new("unusable as hash key: #{key.type}") unless key.is_a?(Hashable)

    value = monkey_eval(value_node, env)
    return value if error?(value)

    hashed = key.hash_key
    pairs[hashed] = HashPair.new(key, value)
  end

  MonkeyHash.new(pairs)
end

def unquote_call?(node)
  node.is_a?(CallExpression) && node.function.token_literal == 'unquote'
end

def convert_object_to_ast_node(obj)
  case obj
  when MonkeyInteger
    t = Token.new(:INT, obj.value.to_s)
    IntegerLiteral.new(t, obj.value)
  when MonkeyBoolean
    t = if obj.value
          Token.new(:TRUE, obj.value.to_s)
        else
          Token.new(:FALSE, obj.value.to_s)
        end
    Boolean.new(t, obj.value)
  when Quote
    obj.node
  end
end

def eval_unquote_calls(quoted, env)
  modify(quoted, lambda do |node|
    return node unless unquote_call?(node)
    return node unless node.is_a?(CallExpression)
    return node unless node.arguments.length == 1

    unquoted = monkey_eval(node.arguments[0], env)
    convert_object_to_ast_node(unquoted)
  end)
end

def quote(node, env)
  node = eval_unquote_calls(node, env)
  Quote.new(node)
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
  when Identifier
    eval_identifier(node, env)
  when StringLiteral
    MonkeyString.new(node.value)
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
  when FunctionLiteral
    parameters = node.parameters
    body = node.body
    Function.new(parameters, body, env)
  when CallExpression
    return quote(node.arguments[0], env) if node.function.token_literal == 'quote'

    function = monkey_eval(node.function, env)
    return function if error?(function)

    args = eval_expressions(node.arguments, env)
    return args[0] if args.length == 1 && error?(args[0])

    apply_function(function, args)
  when ArrayLiteral
    elements = eval_expressions(node.elements, env)
    return elements[0] if elements.length == 1 && error?(elements[0])

    MonkeyArray.new(elements)
  when IndexExpression
    left = monkey_eval(node.left, env)
    return left if error?(left)

    index = monkey_eval(node.index, env)
    return index if error?(index)

    eval_index_expression(left, index)
  when HashLiteral
    eval_hash_literal(node, env)
  end
end

def native_bool_to_boolean_object(value)
  if value
    MONKEY_TRUE
  else
    MONKEY_FALSE
  end
end

def macro_definition?(statement)
  statement.is_a?(LetStatement) && statement.value.is_a?(MacroLiteral)
end

def define_macros(program, env)
  definitions = []
  program.statements.each_with_index do |statement, i|
    if macro_definition?(statement)
      add_macro(statement, env)
      definitions << i
    end
  end
  (definitions.length - 1).downto(0).each do |i|
    definition_index = definitions[i]
    program.statements.delete_at(definition_index)
  end
end

def add_macro(statement, env)
  macro_literal = statement.value
  macro = MonkeyMacro.new(
    macro_literal.parameters,
    macro_literal.body,
    env
  )

  env.set(statement.name.value, macro)
end

def as_macro_call(exp, env)
  return nil unless exp.function.is_a?(Identifier)

  obj = env.get(exp.function.value)
  return nil if obj.nil?
  return nil unless obj.is_a?(MonkeyMacro)

  obj
end

def quote_args(exp)
  args = []
  exp.arguments.each do |arg|
    args << Quote.new(arg)
  end
  args
end

def extend_macro_env(macro, args)
  extended = Environment.new(macro.env)
  macro.parameters.each_with_index do |param, i|
    extended.set(param.value, args[i])
  end
  extended
end

def expand_macros(program, env)
  modify(program, lambda do |node|
    return node unless node.is_a?(CallExpression)

    macro = as_macro_call(node, env)

    args = quote_args(node)
    eval_env = extend_macro_env(macro, args)
    evaluated = monkey_eval(macro.body, eval_env)
    raise MacroCallError, 'we only support returning AST nodes from macros' unless evaluated.is_a?(Quote)

    evaluated.node
  end)
end
