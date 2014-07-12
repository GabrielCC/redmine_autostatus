class ResourceSetting < ActiveRecord::Base
  unloadable
  belongs_to :setting_object, :polymorphic => true
  belongs_to :project

  VIEW_RESOURCES = 1
  EDIT_RESOURCES = 2
  scope :visible, ->(project) { where(setting: VIEW_RESOURCES).where(project_id: project.id) }
  scope :editable, ->(project) { where(setting: EDIT_RESOURCES).where(project_id: project.id) }
  attr_accessible :setting

  def setting_key
    if setting == 2
      :editable
    else
      :visible
    end
  end

end
