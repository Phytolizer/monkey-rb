# frozen_string_literal: true

require_relative 'ast'
require 'test/unit'

## Tests for the Monkey AST directly
class AstTest < Test::Unit::TestCase
  def test_string
    program = Program.new(
      [
        LetStatement.new(
          Token.new(:LET, 'let'),
          Identifier.new(Token.new(:IDENT, 'myVar'), 'myVar'),
          Identifier.new(Token.new(:IDENT, 'anotherVar'), 'anotherVar')
        )
      ]
    )

    assert_equal('let myVar = anotherVar;', program.string)
  end

  def test_modify
    one = -> { IntegerLiteral.new(nil, 1) }
    two = -> { IntegerLiteral.new(nil, 2) }
    turn_one_into_two = lambda do |node|
      return node unless node.is_a?(IntegerLiteral)
      return node unless node.value == 1

      node.value = 2
      node
    end
    test = Struct.new(:input, :expected)
    tests = [
      test.new(one.call, two.call),
      test.new(
        Program.new([ExpressionStatement.new(nil, one.call)]),
        Program.new([ExpressionStatement.new(nil, two.call)])
      ),
      test.new(
        InfixExpression.new(nil, one.call, '+', two.call),
        InfixExpression.new(nil, two.call, '+', two.call)
      ),
      test.new(
        InfixExpression.new(nil, two.call, '+', one.call),
        InfixExpression.new(nil, two.call, '+', two.call)
      ),
      test.new(
        PrefixExpression.new(nil, '-', one.call),
        PrefixExpression.new(nil, '-', two.call)
      ),
      test.new(
        IndexExpression.new(nil, one.call, two.call),
        IndexExpression.new(nil, two.call, two.call)
      ),
      test.new(
        IfExpression.new(
          nil,
          one.call,
          BlockStatement.new(
            nil, [
              ExpressionStatement.new(nil, one.call)
            ]
          ),
          BlockStatement.new(
            nil, [
              ExpressionStatement.new(nil, one.call)
            ]
          )
        ),
        IfExpression.new(
          nil,
          two.call,
          BlockStatement.new(
            nil, [
              ExpressionStatement.new(nil, two.call)
            ]
          ),
          BlockStatement.new(
            nil, [
              ExpressionStatement.new(nil, two.call)
            ]
          )
        )
      ),
      test.new(
        ReturnStatement.new(nil, one.call),
        ReturnStatement.new(nil, two.call)
      ),
      test.new(
        LetStatement.new(nil, nil, one.call),
        LetStatement.new(nil, nil, two.call)
      ),
      test.new(
        FunctionLiteral.new(
          nil,
          [],
          BlockStatement.new(
            nil, [
              ExpressionStatement.new(nil, one.call)
            ]
          )
        ),
        FunctionLiteral.new(
          nil,
          [],
          BlockStatement.new(
            nil, [
              ExpressionStatement.new(nil, two.call)
            ]
          )
        )
      ),
      test.new(
        ArrayLiteral.new(nil, [one.call, one.call]),
        ArrayLiteral.new(nil, [two.call, two.call])
      )
    ]
    tests.each do |tt|
      modified = modify(tt.input, turn_one_into_two)
      assert_equal(tt.expected, modified)
    end

    hash_literal = HashLiteral.new(
      nil, {
        one.call => one.call,
        one.call => two.call
      }
    )
    modify(hash_literal, turn_one_into_two)
    hash_literal.pairs.each do |key, val|
      assert_instance_of(IntegerLiteral, key)
      assert_equal(2, key.value)
      assert_instance_of(IntegerLiteral, val)
      assert_equal(2, val.value)
    end
  end
end
