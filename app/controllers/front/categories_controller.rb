class Front::CategoriesController < Front::BaseController
  def edit_current_group
    render_403 and return if !current_group.organized_by?(current_user) && !current_user&.admin?

    issues = current_group.issues.sort_default.includes(:folders, :category)
    categorised_issues = issues.to_a.group_by{ |issue| issue.category }

    categories = current_group.categories.sort_by{ |category, issues| Category.default_compare_values(category) }

    @categories_with_issues = categories.map do |category|
      [category, categorised_issues[category]]
    end.to_h

    @categories_with_issues[nil] = categorised_issues[nil]

    render layout: 'front/simple'
  end

  def move
    render_403 and return if !current_group.organized_by?(current_user) && !current_user&.admin?

    ActiveRecord::Base.transaction do
      position_payloads = JSON.parse(params[:positions])

      position_payloads.each do |payload|
        category_id = payload['id'] == 'null' ? nil : payload['id']
        issue_ids = payload['channels']
        issue_ids.each_with_index do |issue_id, index|
          issue = current_group.issues.find(issue_id)
          issue.update_attributes(category_id: category_id, position: index + 1)
        end
      end
    end
  end

  def sort
    render_403 and return if !current_group.organized_by?(current_user) && !current_user&.admin?

    render_404 and return if params[:position].blank?
    position = params[:position].to_i
    render_404 and return if position.to_s != params[:position]

    position = position - 1

    current_category = Category.find(params[:id])

    ActiveRecord::Base.transaction do
      categories = current_group.categories.sort_by_default
      categories.to_a.reject{ |category| category == current_category }.insert(position, current_category).each_with_index do |category, index|
        category.update_columns(position: index)
      end
    end
  end
end