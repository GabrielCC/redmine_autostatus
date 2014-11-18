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

  def self.populate
    AutostatusRuleDefinition.destroy_all
    AutostatusTracker.destroy_all
    AutostatusRuleCondition.destroy_all
    AutostatusCurrentStatus.destroy_all

    populating_rules.each do |rule|
      rule_definition = AutostatusRuleDefinition.new
      rule_definition.target_status_id = IssueStatus.find_by_name(rule[:target_status]).id
      rule_definition.save

      rule[:tracker].each do |tracker|
        feature = Tracker.find_by_name tracker
        tracker = AutostatusTracker.new
        tracker.autostatus_rule_definition = rule_definition
        tracker.tracker_id = feature.id
        tracker.save
      end

      rule[:current_status].each do |current_status|
        rule_current_status = AutostatusCurrentStatus.new
        rule_current_status.issue_status_id = IssueStatus.find_by_name(current_status).id
        rule_current_status.autostatus_rule_definition = rule_definition
        rule_current_status.save
      end

      rule[:conditions].each do |condition|
        rule_condition = AutostatusRuleCondition.new
        rule_condition.rule_type = condition[:rule_type]
        rule_condition.tracker_id = Tracker.find_by_name(condition[:tracker]).id if condition[:tracker]
        rule_condition.rule_comparator = condition[:rule_comparator]
        rule_condition.rule_field_first = condition[:rule_field_first]
        rule_condition.rule_field_second = condition[:rule_field_second] if condition[:rule_field_second]
        rule_condition.autostatus_rule_definition = rule_definition
        rule_condition.save

        next unless condition[:rule_values]
        condition[:rule_values].each do |value|
          rule_condition_status = AutostatusRuleConditionStatus.new
          rule_condition_status.issue_status_id = IssueStatus.find_by_name(value).id
          rule_condition_status.autostatus_rule_condition = rule_condition
          rule_condition_status.save
        end
      end
    end
  end

  def self.populating_rules
    [
      {
        # 1. Tracker de tip Feature se va muta in status In Progress cand sunt indeplinite
        # urmatoarele conditii
        # -> feature-ul se afla in statusul Approved sau Ready For Implementation
        # -> cel putin un subtask te tip Task cu statusul In Progress
        target_status: 'In Progress',
        tracker: ['Feature'],
        current_status: ['Approved', 'Ready For Implementation'],
        conditions: [
          {
            rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            tracker:  'Task',
            rule_comparator: :in,
            rule_field_first: :status,
            rule_values: ['In Progress']
          }
        ]
      },
      {
        # 2. Tracker de tip Feature se va muta in status Ready for Testing cand sunt
        # indeplinite urmatoarele conditii:
        # -> feature-ul se afla in statusul In Progress
        # -> toate subtask-urile de tip Task au status final
        # -> toate subtask-urile de tip QA Task cu status New
        target_status: 'Ready for Testing',
        tracker: ['Feature'],
        current_status: ['In Progress'],
        conditions: [
          {
            rule_type: AutostatusRuleCondition::RULE_TYPE_ALL,
            tracker:  'Task',
            rule_comparator: :in,
            rule_field_first: :status,
            rule_values: ['Completed', 'Killed', 'Party', 'Fixed', 'Delivered']
          },
          {
            rule_type: AutostatusRuleCondition::RULE_TYPE_ALL,
            tracker:  'QA Task',
            rule_comparator: :in,
            rule_field_first: :status,
            rule_values: ['New']
          }
        ]
      },
      {
        # 3. Tracker de tip Feature se va muta in status In Testing cand sunt indeplinite
        # urmatoarele conditii:
        # -> feature-ul se afla in statusul Ready For Testing
        # -> toate subtask-urile de tip Task au statusul Closed
        # -> cel putin un subtask de tip QA Task cu status In progress
        target_status: 'In Testing',
        tracker: ['Feature'],
        current_status: ['Ready for Testing'],
        conditions: [
          {
            rule_type: AutostatusRuleCondition::RULE_TYPE_ALL,
            tracker: 'Task',
            rule_comparator: :in,
            rule_field_first: :status,
            rule_values: ['Completed']
          },
          {
            rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            tracker: 'QA Task',
            rule_comparator: :in,
            rule_field_first: :status,
            rule_values: ['In Progress']
          }
        ]
      },
      {
        # 4. Tracker de tip Feature se va muta in status Ready For Implementation cand
        # sunt indeplinite urmatoarele conditii:
        # -> due date > ziua curenta
        # -> o persoana asignata
        # -> o descriere
        # -> asignat intr-un sprint
        # -> o estimare
        target_status: 'Ready For Implementation',
        tracker: ['Feature'],
        current_status: ['New'],
        conditions: [
          {
            rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            rule_comparator: :gt,
            rule_field_first: :due_date,
            rule_field_second: :current_date
          },
          {
            rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            rule_comparator: :not_null,
            rule_field_first: :assignee
          },
          {
            rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            rule_comparator: :not_empty,
            rule_field_first: :description
          },
          {
            rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            rule_comparator: :not_null,
            rule_field_first: :sprint
          },
          {
            rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            rule_comparator: :not_null,
            rule_field_first: :estimation
          }
        ]
      }
    ]
  end
end
