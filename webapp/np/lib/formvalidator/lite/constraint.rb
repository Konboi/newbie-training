require 'formvalidator/lite'

module FormValidator
  module Lite
    module Constraint
      class << self
        def rule(name, &block)
          FormValidator::Lite.rules[name] = block
        end

        def file_rule(name, &block)
          FormValidator::Lite.file_rules[name] = block
        end

        def rule_alias(from, to)
          FormValidator::Lite.rules[to] = FormValidator::Lite.rules[from]
        end

        def delsp(x)
          x.gsub(/\s/, '')
        end
      end

      module Delegator
        def self.delegate(*methods)
          methods.each do |method_name|
            define_method(method_name) do |*args, &block|
              return super(*args, &block) if respond_to? method_name
              Delegator.target.send(method_name, *args, &block)
            end
            private method_name
          end
        end        
                 
        delegate :rule, :file_rule, :rule_alias, :delsp
    
        class << self
          attr_accessor :target
        end

        self.target = Constraint
      end

    end
  end
end

extend FormValidator::Lite::Constraint::Delegator
