class AutostatusCurrentStatus < ActiveRecord::Base
  unloadable
  belongs_to :autostatus_rule_definition
  has_one :issue_status
end
