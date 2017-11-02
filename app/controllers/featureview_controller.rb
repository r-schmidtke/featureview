class FeatureviewController < ApplicationController
  unloadable
  include FeatureviewHelper
  before_filter :define_tracker, :find_project, :select_versions

  def index
    usecasetrackerid = Tracker.where(name: Setting.plugin_featureview['tracker_usecase']).first.id
    servicetrackerid = Tracker.where(name: Setting.plugin_featureview['tracker_systemservice']).first.id
    logicaltrackerid = Tracker.where(name: Setting.plugin_featureview['tracker_fachlogik']).first.id

    allUsecases = Issue.where(tracker_id: usecasetrackerid)
    allServices = Issue.where(tracker_id: servicetrackerid)
    allLogicals = Issue.where(tracker_id: logicaltrackerid)
    @usecases = allUsecases.where(project_id: @project.id)
    @services = allServices.where(project_id: @project.id)
    @logicals = allLogicals.where(project_id: @project.id)
    Project.find(@project.id).children.each do |child|
      @usecases += allUsecases.where(project_id: child.id)
      @services += allServices.where(project_id: child.id)
      @logicals += allLogicals.where(project_id: child.id)
    end
  end

  def show
    @issue = Issue.find(params[:id])
    @relations = @issue.relations
    @changesets = [false]
  end

  def define_tracker
    @relevant_tracker = [];

  end

  def find_project
    @project = Project.find(params[:project_id])
  end

  def select_versions

    # find backlog version for current project
    Version.where(project_id: @project.id).each do |version|
      if version.name.downcase.include? "backlog"
         @backlog = version
      end
    end

    # collect all versions of this project and child projects
    allversions = Version.where(project_id: @project.id)
    @project.children.each do |child|
      allversions += Version.where(project_id: child.id)
    end


    allversions = allversions.reject{ |version| version.name.downcase.include? "backlog" }.sort_by{|v| Gem::Version.new(v)}

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
    @versions = []

    #first pass, to collect all versions that are not completed
    allversions.each do |version|
      unsorted << version if version.completed_percent != 100
    end


    #second pass to filter out the versions that have no relevant open tickets
    trackerids = Tracker.where(name: Setting.plugin_featureview['tracker_names'].split(" ")).ids

    unsorted.each do |version|
      @versions << version if Issue.where(fixed_version_id: version.id, tracker_id: trackerids).where.not(done_ratio: 100).any?
    end

  end



end
