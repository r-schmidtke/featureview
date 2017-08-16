module FeatureviewHelper
  include IssuesHelper


  def progress_bar_special(id, version)
    issue = Issue.find(id)
    if issue.children.where("fixed_version_id = '#{version}'").count >= 1
      return progress_bar(done_ratio_by_version(id, version), :legend => ('%0.0f%' % done_ratio_by_version(id, version)))
    end
    return ""
  end


  def done_ratio_by_version(id, version)
    issue = Issue.find(id)
    done_ratio = 100
    unless Issue.use_status_for_done_ratio? && issue.status && issue.status.default_done_ratio
      issue.children.where("fixed_version_id = '#{version}'").each do |child|
        if child.done_ratio <= done_ratio
          done_ratio = child.done_ratio
        end
      end
    end
    done_ratio
  end


    def render_featureview_lists(issue, tracker)
      s = '<form><table class="list issues">'
      s << content_tag('tr',
             content_tag('th', l(:field_subject), :class => 'subject', :style => 'width: 50%') +
             content_tag('th', l(:field_category)) +
             content_tag('th', l(:field_status)) +
             content_tag('th', l(:label_version)) +
             content_tag('th', l(:label_user)) +
             content_tag('th', '%'))

       issues = issue.descendants.where(tracker_id: tracker)
       if params.has_key?(:version)
         versionids = []
         @project.shared_versions.each do |currentversion|
           if currentversion.name == Version.find(params[:version]).name
            versionids << currentversion.id
           end
         end
         issues = issue.descendants.where(tracker_id: tracker, fixed_version_id: versionids)
       end

      issue_list(issues.visible.preload(:status, :priority, :tracker).where.not(fixed_version_id: nil).sort_by {|everyissue| everyissue.category_id}) do |child, level|
        css = "issue issue-#{child.id} hascontextmenu"
        css << " idnt idnt-#{level}" if level > 0
        s << content_tag('tr',
               content_tag('td', link_to_issue(child, :project => (issue.project_id != child.project_id)), :class => 'subject', :style => 'width: 50%') +
               content_tag('td', h(child.category)) +
               content_tag('td', h(child.status)) +
               content_tag('td', link_to_version(Version.find(child.fixed_version_id))) +
               content_tag('td', link_to_user(child.assigned_to)) +
               content_tag('td', child.disabled_core_fields.include?('done_ratio') ? '' : progress_bar(child.done_ratio)),
               :class => css)
      end
      s << '</table></form>'
      s.html_safe
    end

  def render_featureview_specifications_lists(issue)
    render_featureview_lists(issue, Tracker.where(name: Setting.plugin_featureview['tracker_specification']).first.id)  #todo: check if trackers exist
  end

  def render_featureview_todos_lists(issue)
    render_featureview_lists(issue, Tracker.where(name: Setting.plugin_featureview['tracker_todo']).first.id)  #todo: check if trackers exist
  end

end
