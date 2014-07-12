class AutostatusRuleDefinition < ActiveRecord::Base
  unloadable
  has_many :autostatus_tracker
  has_many :autostatus_current_status
  has_many :autostatus_rule_condition
  belongs_to :target_status, class_name: 'IssueStatus'
  attr_accessible :target_status, :priority


  def self.find_all_by_tracker_and_current_status_id(tracker_id, current_status_id)
    rules_by_current_status = AutostatusCurrentStatus.where(:issue_status_id => current_status_id).pluck(:autostatus_rule_definition_id) 
    if rules_by_current_status.empty? 
      return []
    end
    rules_by_tracker_id = AutostatusTracker.where(:tracker_id => tracker_id).pluck(:autostatus_rule_definition_id)
    if rules_by_tracker_id.empty?
      return []
    end
    AutostatusRuleDefinition.where(:id => (rules_by_tracker_id & rules_by_current_status)).order('priority desc').order('id asc')
  end


  def valid(issue)
    conditions = autostatus_rule_condition
    issue_rule_status = true
    conditions.each { |condition|
      issue_rule_status = issue_rule_status && condition.valid(issue)  
    }
    issue_rule_status
  end
  
  def self.populate
    AutostatusRuleDefinition.destroy_all
    AutostatusTracker.destroy_all
    AutostatusRuleCondition.destroy_all
    AutostatusCurrentStatus.destroy_all
    rules = [
      {
        :target_status => 'In Progress',
        :tracker => ['Feature'],
        :current_status => ['Approved', "Ready For Implementation"],
        :conditions => [
          {
            :rule_type => AutostatusRuleCondition::RULE_TYPE_ONE,
            :tracker =>  'Task',
            :status => ['In Progress']
          }
        ]
      },
# 2. Tracker de tip Feature se va muta in status Ready for Testing cand sunt indeplinite urmatoarele conditii:
# feature-ul se afla in statusul In Progress
# toate subtask-urile de tip Task au status final
# toate subtask-urile de tip QA Task cu status New
      {
        :target_status => 'Ready for Testing',
        :tracker => ['Feature'],
        :current_status => ['In Progress'],
        :conditions => [
          {
            :rule_type => AutostatusRuleCondition::RULE_TYPE_ALL,
            :tracker =>  'Task',
            :status => ["Completed", "Killed", "Party", "Fixed", "Delivered"]
          },
          {
            :rule_type => AutostatusRuleCondition::RULE_TYPE_ALL,
            :tracker =>  'QA Task',
            :status => ['New']
          }

        ]
      },
# 3. Tracker de tip Feature se va muta in status In Testing cand sunt indeplinite urmatoarele conditii:
# feature-ul se afla in statusul Ready For Testing
# toate subtask-urile de tip Task au statusul Closed
# cel putin un subtask de tip QA Task cu status In progress
      {
        :target_status => 'In Testing',
        :tracker => ['Feature'],
        :current_status => ['Ready for Testing'],
        :conditions => [
          {
            :rule_type => AutostatusRuleCondition::RULE_TYPE_ALL,
            :tracker =>  'Task',
            :status => ["Completed"]
          },
          {
            :rule_type => AutostatusRuleCondition::RULE_TYPE_ONE,
            :tracker =>  'QA Task',
            :status => ['In Progress']
          }

        ]
      },
    ]
    rules.each { |rule|
      rule_definition = AutostatusRuleDefinition.new
      rule_definition.target_status_id = IssueStatus.find_by_name(rule[:target_status]).id
      rule_definition.save

      rule[:tracker].each { |tracker|  
        feature = Tracker.find_by_name tracker
        autostatus_tracker = AutostatusTracker.new
        autostatus_tracker.autostatus_rule_definition = rule_definition
        autostatus_tracker.tracker_id = feature.id
        autostatus_tracker.save
      }
      rule[:current_status].each { |current_status|
        autostatus_current_status = AutostatusCurrentStatus.new
        autostatus_current_status.issue_status_id = IssueStatus.find_by_name(current_status).id
        autostatus_current_status.autostatus_rule_definition = rule_definition
        autostatus_current_status.save
      }
      rule[:conditions].each { |condition|  
        autostatus_rule_condition = AutostatusRuleCondition.new
        autostatus_rule_condition.rule_type = condition[:rule_type]
        autostatus_rule_condition.tracker_id = Tracker.find_by_name(condition[:tracker]).id
        autostatus_rule_condition.autostatus_rule_definition = rule_definition
        autostatus_rule_condition.save

        condition[:status].each { |status| 
          autostatus_rule_condition_status = AutostatusRuleConditionStatus.new
          autostatus_rule_condition_status.issue_status_id = IssueStatus.find_by_name(status).id
          autostatus_rule_condition_status.autostatus_rule_condition = autostatus_rule_condition
          autostatus_rule_condition_status.save
        }
      }
    }
  end
end
