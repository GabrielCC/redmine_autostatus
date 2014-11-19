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
  	case rule_type
    when RULE_TYPE_SELF
      condition_valid_for issue
    when RULE_TYPE_SINGLE
      single_rules_valid_for issue
    when RULE_TYPE_ALL
      all_rules_valid_for issue
  	end
  end

  private

  def condition_valid_for(issue)
    first_field_value = issue.send rule_field_first
    result = null_checks_for issue, first_field_value
    return result unless result == :no_match
    result = nexus_check_for issue, first_field_value
    return result unless result == :no_match
    second_field_value = special_field_value_for issue, rule_field_second
    ordering_check_for issue, first_field_value, second_field_value
  end

  def single_rules_valid_for(issue)
    total_valid_children = Issue.where(
      :parent_id => issue.id,
      :status_id => autostatus_rule_condition_statuses.pluck(:issue_status_id),
      :tracker_id => tracker_id,
    ).count
    total_valid_children >= 1
  end

  def all_rules_valid_for(issue)
    total_valid_children = Issue.where(
      :parent_id => issue.id,
      :status_id => autostatus_rule_condition_statuses.pluck(:issue_status_id),
      :tracker_id => tracker_id,
    ).count
    total_children = Issue.where(:parent_id => issue.id, :tracker_id => tracker_id).count
    total_children == total_valid_children && total_children > 0
  end

  def special_field_value_for(issue, field)
    return issue.send(field) unless field =~ /\Aspecial_field_\w+/
    special_field = field[14..-1]
    case special_field
    when 'current_date'
      Date.current
    else
      raise Exception.new 'Unknown special field for the Autostatus Rule Condition'
    end
  end

  def null_checks_for(issue, value)
    case rule_comparator
    when 'null'
      value.nil?
    when 'not_null'
      !value.nil?
    when 'empty'
      value.empty?
    when 'not_empty'
      !value.empty?
    else
    :no_match
    end
  end

  def nexus_check_for(issue, value)
    if rule_comparator == 'in'
      autostatus_rule_condition_statuses.pluck(:id).contains? issue.send(value)
    else
      :no_match
    end
  end

  def ordering_check_for(issue, first_value, second_value)
    return false unless second_value
    return true unless first_value
    case rule_comparator
    when 'gt'
      first_value > second_value
    when 'gte'
      first_value >= second_value
    when 'lt'
      first_value < second_value
    when 'lte'
      first_value <= second_value
    else
      raise Exception.new 'Unknown rule comparator for the Autostatus Rule Condition'
    end
  end
end
