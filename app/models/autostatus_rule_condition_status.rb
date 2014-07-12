class AutostatusRuleConditionStatus < ActiveRecord::Base
  unloadable
  belongs_to :issue_status
  belongs_to :autostatus_rule_condition
end
