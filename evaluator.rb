# frozen_string_literal: true

require_relative 'ast'
require_relative 'object'

def eval_statements(statements)
  result = nil
  statements.each do |stmt|
    result = monkey_eval(stmt)
  end
  result
end

def monkey_eval(node)
  case node
  when Program
    eval_statements(node.statements)
  when ExpressionStatement
    monkey_eval(node.expression)
  when IntegerLiteral
    MonkeyInteger.new(node.value)
  end
end
