# frozen_string_literal: true

## A Monkey object, represented as an "abstract class" in Ruby
module MonkeyObject
  def type
    raise NotImplementedError, 'Object::type is not meant to be callable'
  end

  def inspect
    raise NotImplementedError, 'Object::inspect is not meant to be called'
  end
end

## A Monkey integer
class MonkeyInteger
  include MonkeyObject

  def initialize(value)
    @value = value
  end

  def type
    :INTEGER
  end

  def inspect
    @value.to_s
  end

  attr_reader :value
end

## A Monkey boolean
class MonkeyBoolean
  include MonkeyObject

  def initialize(value)
    @value = value
  end

  def type
    :BOOLEAN
  end

  def inspect
    @value.to_s
  end

  attr_reader :value
end

## The null value. Notorious for its dangers.
class MonkeyNull
  include MonkeyObject

  def type
    :NULL
  end

  def inspect
    'null'
  end
end

## A wrapped return value. This is a shell that signals
## it should be bubbled up through the AST on evaluation.
class ReturnValue
  include MonkeyObject

  def initialize(value)
    @value = value
  end

  def type
    :RETURN_VALUE
  end

  def inspect
    @value.inspect
  end

  attr_reader :value
end

## A Monkey runtime error.
## It's an object so that we don't get cascading errors.
class MonkeyError
  include MonkeyObject

  def initialize(message)
    @message = message
  end

  def type
    :ERROR
  end

  def inspect
    "ERROR: #{@message}"
  end

  attr_reader :message
end

## A Monkey environment, storing values for names.
class Environment
  def initialize(outer = nil)
    @outer = outer
    @store = {}
  end

  def get(name)
    val = @store[name]
    val = @outer.get(name) if val.nil? && !@outer.nil?
    val
  end

  def set(name, val)
    @store[name] = val
    val
  end
end

## A Monkey function.
class Function
  def initialize(parameters, body, env)
    @parameters = parameters
    @body = body
    @env = env
  end

  attr_reader :parameters, :body, :env

  def type
    :FUNCTION
  end

  def inspect
    "fn(#{@parameters.map(&:string).join}) {\n#{@body.string}\n}"
  end
end

## A Monkey string.
class MonkeyString
  include MonkeyObject

  def initialize(value)
    @value = value
  end

  attr_reader :value

  def type
    :STRING
  end

  def inspect
    @value
  end
end

## A built-in function.
class MonkeyBuiltin
  include MonkeyObject

  def initialize(func)
    @fn = func
  end

  attr_reader :fn

  def type
    :BUILTIN
  end

  def inspect
    'built-in function'
  end
end

## An array.
class MonkeyArray
  include MonkeyObject

  def initialize(elements)
    @elements = elements
  end

  attr_reader :elements

  def type
    :ARRAY
  end

  def inspect
    "[#{@elements.map(&:inspect).join(', ')}]"
  end
end
