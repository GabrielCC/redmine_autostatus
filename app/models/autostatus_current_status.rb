class AutostatusCurrentStatus < ActiveRecord::Base
  unloadable
  belongs_to :autostatus_rule_definition
  belongs_to :issue_status
end
