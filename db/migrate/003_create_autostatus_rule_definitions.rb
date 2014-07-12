class CreateAutostatusRuleDefinitions < ActiveRecord::Migration
  def change
    create_table :autostatus_rule_definitions do |t|
      t.integer :target_status_id
      t.integer :priority, :default => 0
    end
  end
end
