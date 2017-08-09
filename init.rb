
Redmine::Plugin.register :featureview do
  name 'Featureview plugin'
  author 'Robin Schmidtke'
  description 'specialized views for product features'
  version '0.0.1'
    
  project_module :featureview do
    permission :featureview, { :featureview => [:index, :show] }, :public => true
  end
  menu :project_menu, :featureview, { :controller => 'featureview', :action => 'index' }, :caption => :label_featureview, :after => :activity, :param => :project_id
  settings :default => {}, :partial => 'settings/featureview_settings'
end
