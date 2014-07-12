module AutostatusIssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
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
      rules = AutostatusRuleDefinition.find_all_by_tracker_and_current_status_id(tracker_id, status_id)
      rules.each { |rule|
        if rule.valid(self)
          self.status_id = rule.target_status_id
          save
        end  
      }
    end
  end    
end
