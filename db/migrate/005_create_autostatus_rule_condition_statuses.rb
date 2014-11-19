class CreateAutostatusRuleConditionStatuses < ActiveRecord::Migration
  def change
    create_table :autostatus_rule_condition_statuses do |t|
      t.references :autostatus_rule_condition
      t.references :issue_status
    end
    add_index :autostatus_rule_condition_statuses, :autostatus_rule_condition_id, :name => 'autostatus_rule_condition_statuses_condition'
    add_index :autostatus_rule_condition_statuses, :issue_status_id, :name => 'autostatus_rule_condition_statuses_status'
  end
end
