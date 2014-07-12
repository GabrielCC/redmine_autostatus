class Department < ActiveRecord::Base
  attr_accessible :name
  has_many :resources
  validates :name, uniqueness: true

  def to_s
  	name 
  end
end
