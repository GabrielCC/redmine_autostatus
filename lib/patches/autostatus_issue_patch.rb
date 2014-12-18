module AutostatusIssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      around_save :trigger_autostatus_rules
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    private

    def trigger_autostatus_rules
      manually_changed = status_id_changed?
      yield
      return if manually_changed
      apply_autostatus_rules
      parent.apply_autostatus_rules if parent
    end

    def apply_autostatus_rules
      rules = AutostatusRuleDefinition.find_all_for(tracker_id, status_id)
      old_status = nil
      new_status = nil
      rules.each do |rule|
        next unless rule.valid self
        old_status ||= self.status.name
        self.status_id = rule.target_status_id
        new_status = self.status.name
        save!
      end
      return unless old_status
      journal = init_journal(User.current, '')
      add_status_chage_to journal.details, old_status
      add_autostatus_notice_to journal.details
      journal.save!
    end
  end

  def add_status_chage_to(details, old_status)
    details.each do |detail|
      next unless detail.prop_key == 'status_id'
      detail.old_value = old_status
      detail.value = self.status.name
      return
    end
    details << JournalDetail.new(property: 'attr',
                                 prop_key: 'status',
                                 old_value: old_status,
                                 value: self.status.name)
  end

  def add_autostatus_notice_to(details)
    details.each do |detail|
      next unless detail.prop_key == 'autostatus'
      return
    end
    details << JournalDetail.new(property: 'attr',
                                 prop_key: 'autostatus',
                                 value: 'Changed automatically')
  end
end
