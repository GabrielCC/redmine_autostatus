class AutostatusRuleCondition < ActiveRecord::Base
  unloadable
  belongs_to :tracker
  belongs_to :autostatus_rule_definition
  has_many :autostatus_rule_condition_statuses
  has_many :issue_statuses, through: :autostatus_rule_condition_statuses
  RULE_TYPE_SELF = 0;
  RULE_TYPE_SINGLE = 1;
  RULE_TYPE_ALL = 2;

  def valid(issue)
  	@total_valid_children = Issue.where(
  		:parent_id => issue.id,
  		:status_id => autostatus_rule_condition_statuses.pluck(:issue_status_id),
  		:tracker_id => tracker_id,
  		).count
  	case rule_type
    when RULE_TYPE_SELF
      self_rules_valid_for issue
    when RULE_TYPE_SINGLE
      single_rules_valid?
    when RULE_TYPE_ALL
      all_rules_valid?
  	end
  end

  private

  def self_rules_valid_for(issue)
    case rule_comparator
    when :gt
      issue.send(rule_field_first) > issue.send(rule_field_second)
    when :gte
      issue.send(rule_field_first) >= issue.send(rule_field_second)
    when :lt
      issue.send(rule_field_first) < issue.send(rule_field_second)
    when :lte
      issue.send(rule_field_first) <= issue.send(rule_field_second)
    when :null
      issue.send(rule_field_first).nil?
    when :not_null
      !issue.send(rule_field_first).nil?
    when :empty
      issue.send(rule_field_first).empty?
    when :not_empty
      !issue.send(rule_field_first).empty?
    else
      raise Exception.new 'Unknown rule comparator for the Autostatus Rule Condition'
    end
  end

  def single_rules_valid?
    @total_valid_children >= 1
  end

  def all_rules_valid?
    total_children = Issue.where(:parent_id => issue.id, :tracker_id => tracker_id).count
    total_children == @total_valid_children && total_children > 0
  end
end
