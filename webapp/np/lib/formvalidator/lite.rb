require 'ext/object/blank'

module FormValidator
  module Lite
    class << self
      attr_accessor :rules, :file_rules

      def new(q)
        Validator.new(q)
      end
    end

    self.rules      = {}
    self.file_rules = {}

    class Validator
      attr_accessor :query, :error, :error_ary

      def initialize(q)
        @query     = q
        @error     = Hash.new{|h,k| h[k] = {}}
        @error_ary = []
      end

      def check(*rule_ary)
        rule_ary.each_slice(2) do |key, rules|
          values = []
          if key.is_a?(Hash)
            key = key.flatten
            values = [key[1].map {|v| @query.params[v]}]
            key = key[0]
          else
            values = @query.params[key].present? ? [*@query.params[key]] : [nil]
          end

          values.each do |value|
            rules.each do |rule|
              rule_name = rule.is_a?(Array) ? rule[0] : rule
              args      = rule.is_a?(Array) ? rule.slice(1, rule.length-1) : []

              is_ok = Proc.new do
                if value.blank? && !rule_name.match(/\A(NOT_NULL|NOT_BLANK|REQUIRED)\z/)
                  true
                else
                  code = FormValidator::Lite.rules[rule_name]
                  code.call(value, *args)
                end
              end.call

              unless is_ok
                self.set_error(key, rule_name)
              end
            end
          end
        end

        self
      end

      def is_error?(key)
        @error[key].present?
      end

      def is_valid?
        !self.has_error?
      end

      def has_error?
        @error.present?
      end

      def set_error(param, rule_name)
        @error[param][rule_name] ||= 0
        @error[param][rule_name] += 1

        @error_ary.push [param, rule_name]
      end

      def errors
        @error
      end

      def self.load_constraints(*constraints)
        # TODO
      end

    end

  end
end

require 'formvalidator/lite/constraint/default'
