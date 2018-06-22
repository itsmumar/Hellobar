module Admin::ApplicationHelper
  def yes_or_no(value)
    if value
      'Yes'
    else
      'No'
    end
  end
end
