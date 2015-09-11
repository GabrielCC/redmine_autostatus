namespace 'redmine:plugins:redmine_autostatus' do
  desc "Populate the autostatus tables with Zitec's rules"
  task populate: :environment do
    populate_autostatus_rules
  end

  def remove_old_rules
    AutostatusRuleDefinition.destroy_all
    AutostatusTracker.destroy_all
    AutostatusRuleCondition.destroy_all
    AutostatusCurrentStatus.destroy_all
    AutostatusRuleConditionStatus.destroy_all
  end

  def self.populating_rules
    [
      {
        # 1. Tracker de tip Feature se va muta in status In Progress cand sunt
        # indeplinite urmatoarele conditii
        # -> feature-ul se afla in statusul Ready For Implementation
        # -> cel putin un subtask te tip Task cu statusul In Progress
        target_status: 'In Progress', tracker: ['Feature'],
        current_status: ['Ready For Implementation'],
        conditions: [{ rule_type: AutostatusRuleCondition::RULE_TYPE_SINGLE,
          tracker:  'Task', rule_comparator: 'in',
          rule_field_first: 'status_id', rule_values: ['In Progress'] }]
      },
      {
        # 2. Tracker de tip Feature se va muta in status Ready for Testing cand
        # sunt indeplinite urmatoarele conditii:
        # -> feature-ul se afla in statusul In Progress
        # -> toate subtask-urile de tip Task au status final
        # -> toate subtask-urile de tip QA Task cu status New
        target_status: 'Ready for Testing', tracker: ['Feature'],
        current_status: ['In Progress'],
        conditions: [
          { rule_type: AutostatusRuleCondition::RULE_TYPE_ALL,
            tracker:  'Task', rule_comparator: 'in',
            rule_field_first: 'status_id', rule_values: ['Done', 'Killed'] },
          { rule_type: AutostatusRuleCondition::RULE_TYPE_ALL,
            tracker:  'QA Task', rule_comparator: 'in',
            rule_field_first: 'status_id', rule_values: ['New'] }
        ]
      },
      {
        # 3. Tracker de tip Feature se va muta in status In Testing cand sunt
        # indeplinite urmatoarele conditii:
        # -> feature-ul se afla in statusul Ready For Testing
        # -> toate subtask-urile de tip Task au statusul Completed
        # -> cel putin un subtask de tip QA Task cu status In progress
        target_status: 'In Testing', tracker: ['Feature'],
        current_status: ['Ready for Testing'],
        conditions: [
          { rule_type: AutostatusRuleCondition::RULE_TYPE_ALL,
            tracker: 'Task', rule_comparator: 'in',
            rule_field_first: 'status_id', rule_values: ['Done'] },
          { rule_type: AutostatusRuleCondition::RULE_TYPE_SINGLE,
            tracker: 'QA Task', rule_comparator: 'in',
            rule_field_first: 'status_id', rule_values: ['In Progress'] }
        ]
      },
      {
        # 4. Tracker de tip Feature se va muta in status Ready For
        # Implementation cand sunt indeplinite urmatoarele conditii:
        # -> due date > ziua curenta
        # -> o persoana asignata
        # -> o descriere
        # -> asignat intr-un sprint
        # -> o estimare
        target_status: 'Ready For Implementation', tracker: ['Feature'],
        current_status: ['New'],
        conditions: [
          { rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            rule_comparator: 'not_null', rule_field_first: 'assigned_to' },
          { rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            rule_comparator: 'not_empty', rule_field_first: 'description' },
          { rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            rule_comparator: 'not_null', rule_field_first: 'fixed_version' },
          { rule_type: AutostatusRuleCondition::RULE_TYPE_SELF,
            rule_comparator: 'not_null', rule_field_first: 'estimated_hours' }
        ]
      }
    ]
  end

  def create_autostatus_tracker_from(rule_definition, tracker)
    feature = Tracker.where(name: tracker).first
    tracker = AutostatusTracker.new
    tracker.autostatus_rule_definition = rule_definition
    tracker.tracker_id = feature.id
    tracker.save!
  end

  def create_current_status_from(rule_definition, current_status)
    rule_current_status = AutostatusCurrentStatus.new
    rule_current_status.issue_status_id = IssueStatus.where(
      name: current_status).first.id
    rule_current_status.autostatus_rule_definition = rule_definition
    rule_current_status.save
  end

  def create_condition_rule_status_from(rule_condition, value)
    rule_condition_status = AutostatusRuleConditionStatus.new
    rule_condition_status.issue_status_id = IssueStatus.where(name: value)
      .first.id
    rule_condition_status.autostatus_rule_condition = rule_condition
    rule_condition_status.save!
  end

  def create_condition_from(rule_definition, condition)
    rule_condition = AutostatusRuleCondition.new
    rule_condition.rule_type = condition[:rule_type]
    if condition[:tracker]
      rule_condition.tracker_id = Tracker.where(name: condition[:tracker])
        .first.id
    end
    rule_condition.rule_comparator = condition[:rule_comparator]
    rule_condition.rule_field_first = condition[:rule_field_first]
    if condition[:rule_field_second]
      rule_condition.rule_field_second = condition[:rule_field_second]
    end
    rule_condition.autostatus_rule_definition = rule_definition
    rule_condition.save!
    return unless condition[:rule_values]
    condition[:rule_values].each do |value|
      create_condition_rule_status_from rule_condition, value
    end
  end

  def create_autostatus_transition_from(rule)
    rule_definition = AutostatusRuleDefinition.new
    rule_definition.target_status_id = IssueStatus.where(
      name: rule[:target_status]).first.id
    rule_definition.save!
    rule[:tracker].each do |tracker|
      create_autostatus_tracker_from rule_definition, tracker
    end
    rule[:current_status].each do |current_status|
      create_current_status_from rule_definition, current_status
    end
    rule[:conditions].each do |condition|
      create_condition_from rule_definition, condition
    end
  end

  def populate_autostatus_rules
    remove_old_rules
    populating_rules.each do |rule|
      create_autostatus_transition_from rule
    end
  end
end
