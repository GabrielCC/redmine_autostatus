class AddColumnsToAutostatusRuleConditions < ActiveRecord::Migration
  def change
    add_column :autostatus_rule_conditions, :rule_comparator, :string
    add_column :autostatus_rule_conditions, :rule_field_first, :string
    add_column :autostatus_rule_conditions, :rule_field_second, :string
  end
end
