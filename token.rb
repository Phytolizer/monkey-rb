class Token
    def initialize(type, literal)
        @type = type
        @literal = literal
    end

    attr_reader :type, :literal
end
