ActionDispatch::Callbacks.to_prepare do
  paths = '/lib/redmine_autostatus/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) << paths).each do |file|
    require_dependency file
  end
end

Redmine::Plugin.register :redmine_autostatus do
  name 'Autostatus'
  author 'Zitec'
  description 'Rules for automatic status transition.'
  version '1.0.2'
  url 'https://github.com/sdwolf/redmine_autostatus'
  author_url 'http://www.zitec.com'
end
