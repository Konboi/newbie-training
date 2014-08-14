require 'formvalidator/lite/constraint'
require 'ext/object/blank'

rule 'NOT_NULL' do |value|
  value.present?
end
rule_alias 'NOT_NULL', 'NOT_BLANK'
rule_alias 'NOT_NULL', 'REQUIRED'

rule 'INT' do |value|
  # TODO
end
rule 'UINT' do |value|
  # TODO
end

rule 'ASCII' do |value|
  value === /\A[\x21-\x7E]+\z/
end

rule 'DUPLICATION' do |values|
  values[0] and values[1] and values[0] == values[1]
end
rule_alias 'DUPLICATION', 'DUP'

rule 'LENGTH' do |value, min, max=min|
  length = value.length
  min.to_i <= length and length <= max.to_i
end

rule 'EQUAL' do |value, expected|
  # TODO
end

rule 'REGEX' do |value, regex|
  regex === value
end
rule_alias 'REGEX', 'REGEXP'

rule 'CHOICE' do |value, choices|
  # TODO
end
rule_alias 'CHOICE', 'IN'

rule 'NOT_IN' do |value, choices|
  # TODO
end

rule 'MATCH' do |value, &block|
  # TODO
end
