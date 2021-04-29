# frozen_string_literal: true

require 'digest/sha1'

## A Monkey object, represented as an "abstract class" in Ruby
module MonkeyObject
  def type
    raise NotImplementedError, 'Object::type is not meant to be callable'
  end

  def inspect
    raise NotImplementedError, 'Object::inspect is not meant to be called'
  end
end

## A hashable object, required to implement HashKey
module Hashable
  ## Get the hash key of this object which will be used in a MonkeyHash.
  def hash_key
    raise NotImplementedError, 'Hashable::hash_key is not meant to be called'
  end
end

## A key for a MonkeyHash
HashKey = Struct.new(:type, :value)

## A Monkey integer
class MonkeyInteger
  include MonkeyObject
  include Hashable

  ## Create a MonkeyInteger from a native int.
  def initialize(value)
    @value = value
  end

  ## Always returns INTEGER.
  def type
    :INTEGER
  end

  ## Convert this MonkeyInteger to a string.
  def inspect
    @value.to_s
  end

  ## An integer's hash key is its value.
  def hash_key
    HashKey.new(type, @value)
  end

  attr_reader :value
end

## A Monkey boolean
class MonkeyBoolean
  include MonkeyObject
  include Hashable

  ## Convert a bool to a MonkeyBoolean.
  def initialize(value)
    @value = value
  end

  ## Always returns BOOLEAN.
  def type
    :BOOLEAN
  end

  ## Convert the MonkeyBoolean to a string.
  def inspect
    @value.to_s
  end

  ## The hash key of a boolean is 1 if it is true, 0 otherwise.
  def hash_key
    value = if @value
              1
            else
              0
            end

    HashKey.new(type, value)
  end

  attr_reader :value
end

## The null value. Notorious for its dangers.
class MonkeyNull
  include MonkeyObject

  ## Always returns NULL.
  def type
    :NULL
  end

  ## Returns 'null'.
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
  include Hashable

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

  def hash_key
    value = Digest::SHA1.hexdigest(@value)
    HashKey.new(type, value)
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

## A Monkey key-value pair
class HashPair
  def initialize(key, value)
    @key = key
    @value = value
  end

  attr_reader :key, :value
end

## A Monkey hash, represented as a Ruby hash with HashKey keys and HashPair values
class MonkeyHash
  def initialize(pairs)
    @pairs = pairs
  end

  attr_reader :pairs

  def type
    :HASH
  end

  def inspect
    pairs = []
    @pairs.each do |_, pair|
      pairs << "#{pair.key.inspect}: #{pair.value.inspect}"
    end
    "{#{pairs.join(', ')}}"
  end
end
