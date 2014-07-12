class IssueResource < ActiveRecord::Base
  unloadable
  belongs_to :issue, :touch => true
  belongs_to :resource
  validates_presence_of :issue_id, :resource_id, :estimation
  validates :estimation, numericality: { only_integer: true }
  validates_uniqueness_of :issue_id, :scope => :resource_id, :message => ' only one estimation for resource'

  after_create 'save_journal(:created)'
  after_destroy 'save_journal(:deleted)'
  after_update 'save_journal(:updated)'

  JOURNAL_DETAIL_PROPERTY = 'resource-estimation'

  def self.from_params(params)
    issue_resource = IssueResource.new
    project = Project.find params[:project_id]
    issue = Issue.find params[:issue_id]
    begin
      resource = Resource.find params[:resource_id]  
    rescue Exception => e
      resource = Resource.new
    end
    unless project.nil? || issue.nil?
      issue_resource.issue = issue
      issue_resource.resource = resource
      issue_resource.estimation = params[:estimation]
    end
    issue_resource
  end

  def to_json
    hash = {}
    hash[:estimation] = self.estimation
    hash[:code] = self.resource.code
    hash
  end

  private

  def journal_note(operation)
    messages = {
      :created => " created #{resource.code} #{estimation}h",
      :updated => " changed from #{resource.code} #{estimation_was}h to #{resource.code} #{estimation}h",
      :deleted => " deleted #{resource.code} #{estimation}h"
    }
    messages[operation]
  end

  def save_journal(operation)
    journal = issue.init_journal(User.current, nil)
    journal.details << JournalDetail.new(:property => IssueResource::JOURNAL_DETAIL_PROPERTY,
                                  :prop_key => id,
                                  :old_value => '',
                                  :value => journal_note(operation))
    journal.save
  end
end
