module AutostatusIssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      after_save :trigger_autostatus_rules
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def trigger_autostatus_rules
      apply_autostatus_rules
      # unless parent.nil?
      #   parent.apply_autostatus_rules
      # end
    end

    def apply_autostatus_rules
      #find if we have rules
      rules = AutostatusRuleDefinition.find_all_for(tracker_id, status_id)
      rules.each do |rule|
        next unless rule.valid self
        old_status = self.status.name
        self.status_id = rule.target_status_id
        next unless save
        journal = init_journal(User.current, '')
        journal.details << JournalDetail.new(property: 'attr',
                                             prop_key: 'status',
                                             old_value: old_status,
                                             value: self.status.name)
        journal.save!
      end
    end
  end
end
