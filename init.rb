ActionDispatch::Callbacks.to_prepare do
  paths = '/lib/redmine_autostatus/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) << paths).each do |file|
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
