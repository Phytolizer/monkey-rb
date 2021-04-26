# frozen_string_literal: true

## The unit of the Monkey programming language.
class Token
  def initialize(type, literal)
    @type = type
    @literal = literal
  end

  attr_reader :type, :literal
end

## Methods associated with low-level token manipulation.
module Tokens
  KEYWORDS = {
    'let' => :LET,
    'fn' => :FUNCTION,
    'if' => :IF,
    'else' => :ELSE,
    'return' => :RETURN,
    'true' => :TRUE,
    'false' => :FALSE,
    'macro' => :MACRO
  }.freeze
  def self.lookup_ident(ident)
    if KEYWORDS.key?(ident)
      KEYWORDS[ident]
    else
      :IDENT
    end
  end
end
