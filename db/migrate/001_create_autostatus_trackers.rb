class CreateAutostatusTrackers < ActiveRecord::Migration
  def change
    create_table :autostatus_trackers do |t|

      t.references :tracker

      t.references :autostatus_rule_definition


    end

    add_index :autostatus_trackers, :traker_id

    add_index :autostatus_trackers, :autostatus_rule_definition_id, :name => 'autostatus_tracker_rule_definition'

  end
end
