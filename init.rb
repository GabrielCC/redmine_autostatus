require "redmine"

# Patches to the Redmine core.
ActionDispatch::Callbacks.to_prepare do
  Dir[File.dirname(__FILE__) + '/lib/redmine_autostatus/patches/*_patch.rb'].each do |file|
    require_dependency file
  end
end

Redmine::Plugin.register :redmine_autostatus do
  name 'Redmine Autostatus'
  author 'Gabriel Croitoru'
  description 'Redmine Autostatus Plugin for Parent Features'
  version '1.0.1'
  url 'http://gabrielcc.github.io/redmine_autostatus'
  author_url 'http://gabrielcc.github.io/'
end