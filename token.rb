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
    'fn' => :FUNCTION
  }.freeze
  def self.lookup_ident(ident)
    if KEYWORDS.has_key?(ident)
      KEYWORDS[ident]
    else
      :IDENT
    end
  end
end
