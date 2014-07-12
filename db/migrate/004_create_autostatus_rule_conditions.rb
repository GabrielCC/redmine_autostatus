class CreateAutostatusRuleConditions < ActiveRecord::Migration
  def change
    create_table :autostatus_rule_conditions do |t|
      t.integer :rule_type
      t.references :tracker
      t.references :autostatus_rule_definition

    end

    add_index :autostatus_rule_conditions, :tracker_id

  end
end
