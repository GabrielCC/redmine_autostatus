class AutostatusRuleDefinition < ActiveRecord::Base
  unloadable
  has_many :autostatus_tracker
  has_many :autostatus_current_status
  has_many :autostatus_rule_condition
  has_one :target_status, class_name:
end
