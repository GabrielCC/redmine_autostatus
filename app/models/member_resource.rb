class MemberResource < ActiveRecord::Base
  belongs_to :resource
  belongs_to :member
end
