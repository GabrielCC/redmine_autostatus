class CreateAutostatusCurrentStatuses < ActiveRecord::Migration
  def change
    create_table :autostatus_current_statuses do |t|
      t.references :issue_status
      t.references :autostatus_rule_definition
    end
    add_index :autostatus_current_statuses, :issue_status_id
    add_index :autostatus_current_statuses, :autostatus_rule_definition_id,  :name => 'autostatus_status_rule_definition'

  end
end
