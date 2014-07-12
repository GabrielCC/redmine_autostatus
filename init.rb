require "redmine"

# Patches to the Redmine core.
ActionDispatch::Callbacks.to_prepare do 
  # require_dependency 'member'
  # require 'patches/membership_patch'
  # # Guards against including the module multiple time (like in tests)
  # # and registering multiple callbacks
  # unless Member.included_modules.include? MembershipPatch
  #   Member.send(:include, MembershipPatch)
  # end

end

Redmine::Plugin.register :redmine_autostatus do
  name 'Redmine Autostatus'
  author 'Gabriel Croitoru'
  description 'Redmine Autostatus Plugin for Parent Features'
  version '1.0.0'
  url 'http://gabrielcc.github.io/redmine_autostatus'
  author_url 'http://gabrielcc.github.io/'
  


end