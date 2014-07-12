class RemoveColumnFromConditions < ActiveRecord::Migration
  def change
    remove_column :autostatus_rule_conditions, :status_id
  end
end
