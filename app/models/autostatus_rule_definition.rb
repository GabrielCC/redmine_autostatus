class AutostatusRuleDefinition < ActiveRecord::Base
  unloadable
  has_many :autostatus_tracker
  has_many :autostatus_current_status
  has_many :autostatus_rule_condition
  belongs_to :target_status, class_name: 'IssueStatus'
  attr_accessible :target_status, :priority

  def self.find_all_for(tracker_id, current_status_id)
    rules_by_current_status = AutostatusCurrentStatus.where(
      issue_status_id: current_status_id).pluck(:autostatus_rule_definition_id)
    if rules_by_current_status.empty?
      return []
    end
    rules_by_tracker_id = AutostatusTracker.where(
      tracker_id: tracker_id).pluck(:autostatus_rule_definition_id)
    if rules_by_tracker_id.empty?
      return []
    end
    AutostatusRuleDefinition.where(
      id: (rules_by_tracker_id & rules_by_current_status)
    ).order('priority desc').order('id asc')
  end

  def valid(issue)
    autostatus_rule_condition.each do |condition|
      return false unless condition.valid(issue)
    end
    true
  end
end
