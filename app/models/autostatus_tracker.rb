class AutostatusTracker < ActiveRecord::Base
  unloadable
  has_one :tracker
  belongs_to :autostatus_rule_definition
end
