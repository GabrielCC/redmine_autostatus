class Resource < ActiveRecord::Base
  belongs_to :department
  has_many :member_resource
  has_many :project_resource
  has_many :member, :through => :member_resource
  has_many :project, :through => :project_resource
  attr_accessible :code, :name, :department
  validates :name, uniqueness: true, presence: true
  validates :code, uniqueness: true, presence: true
  validates :department, presence: true

  def self.find_or_create_by_params(params)
  	resource = self.find_or_initialize_by_name_and_code(params[:name], params[:code])
  	if resource.new_record?
  		department = Department.find_or_initialize_by_name(params[:department_name])
  		if department.new_record?
  			department.save
  		end
  		resource.department = department
  		resource.save!
  	end
  	resource
  end
end
