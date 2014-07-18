class AutostatusRuleCondition < ActiveRecord::Base
  unloadable
  belongs_to :tracker
  belongs_to :autostatus_rule_definition
  has_many :autostatus_rule_condition_statuses
  has_many :issue_statuses, through: :autostatus_rule_condition_statuses
  RULE_TYPE_ONE = 1;
  RULE_TYPE_ALL = 2;

  def valid(issue)
  	total_valid_children = Issue.where(
  		:parent_id => issue.id, 
  		:status_id => autostatus_rule_condition_statuses.pluck(:issue_status_id),
  		:tracker_id => tracker_id,
  		).count
  	status = false
  	case rule_type
  	 when RULE_TYPE_ONE
  	 	status = total_valid_children >= 1
  	 when RULE_TYPE_ALL
     	total_children =  Issue.where(
  		:parent_id => issue.id, 
  		:tracker_id => tracker_id,
  		).count
  		status = (total_children == total_valid_children && total_children > 0)
  	 end
  	 status
  end
end
