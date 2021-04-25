# frozen_string_literal: true

module Node
  def token_literal
    @token.literal
  end
end

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

  attr_reader :statements
end

class LetStatement
  include Node

  def initialize(token, name, value)
    @token = token
    @name = name
    @value = value
  end

  attr_reader :token, :name, :value
end

class Identifier
  include Node

  def initialize(token, value)
    @token = token
    @value = value
  end

  attr_reader :token, :value
end

class ReturnStatement
  include Node

  def initialize(token, return_value)
    @token = token
    @return_value = return_value
  end

  attr_reader :token, :return_value
end
