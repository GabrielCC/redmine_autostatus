class AutostatusRuleCondition < ActiveRecord::Base
  unloadable
  has_one :tracker
  belongs_to :autostatus_rule_definition
  has_one :status, class_name: "IssueStatus"
end
