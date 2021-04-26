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
