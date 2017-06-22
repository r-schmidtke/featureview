class FeatureviewController < ApplicationController
  unloadable
  include FeatureviewHelper
  before_filter :find_project, :select_versions

  def index
    usecasetrackerid = Tracker.where(name: Setting.plugin_featureview['tracker_usecase']).first.id
    servicetrackerid = Tracker.where(name: Setting.plugin_featureview['tracker_systemservice']).first.id
    @usecases = Issue.where(tracker_id: usecasetrackerid, project_id: @project.id)
    @services = Issue.where(tracker_id: servicetrackerid, project_id: @project.id)
  end

  def show
    @issue = Issue.find(params[:id])
    @relations = @issue.relations
  end


  def find_project
    @project = Project.find(params[:project_id])
  end

  def select_versions

    Version.where(project_id: @project.id).each do |version|
      if version.name.downcase.include? "backlog"
         @backlog = version
      end
    end

    allversions = Version.where(project_id: @project.id).reject{ |version| version.name.downcase.include? "backlog" }

    customfield = CustomField.all.where(name: Setting.plugin_featureview['version_field']).last

    return allversions unless customfield

    #Iteration marker stuff below
    current = 0
    #find number of versions and index of current iteration
    allversions.each.with_index do |version, index|
        value = CustomValue.where(customized_id: version.id, custom_field_id: customfield.id).last
        if value
          if value.value == "1"
            current = index
          end
        end
    end
    allversions.each.with_index do |version, index|
      iteration = 0
      iteration -= current
      iteration += index
      if iteration == 0
        version.update_attribute(:extra, "N")
      else
        if iteration > 0
          version.update_attribute(:extra, "N+" + iteration.to_s)
        else
          version.update_attribute(:extra, "N" + iteration.to_s)
        end
      end
    end

    #update version iteration custom fields
    CustomValue.where(custom_field_id: customfield.id).each do |customvalue|
      if Version.find(customvalue.customized_id).extra != "N"
          customvalue.update_attribute(:value, "0")
      end
    end
    unsorted = []
    allversions.each do |version|
      unsorted << version if version.completed_percent != 100 && Issue.where(fixed_version_id: version.id).first
    end
    @versions = unsorted
  end



end
