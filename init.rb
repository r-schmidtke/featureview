
Redmine::Plugin.register :featureview do
  name 'Featureview plugin'
  author 'Robin Schmidtke'
  description 'specialized views for product features'
  version '0.0.1'

    permission :featureview, { :featureview => [:index, :show] }, :public => true
    menu :project_menu, :featureview, { :controller => 'featureview', :action => 'index' }, :caption => 'Leistungsmerkmale', :after => :activity, :param => :project_id
    settings :default => {}, :partial => 'settings/featureview_settings'
end
