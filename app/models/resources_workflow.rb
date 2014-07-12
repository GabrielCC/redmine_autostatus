class ResourcesWorkflow < ActiveRecord::Base
  unloadable
  belongs_to :project
  belongs_to :old_status, :class_name => 'IssueStatus', :foreign_key => 'old_status_id'
  belongs_to :new_status, :class_name => 'IssueStatus', :foreign_key => 'new_status_id'

end


