# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def date_to_array(date)
    date_form       = {}
    if date.nil?
      date_form[:day]   = Date.today.day
      date_form[:month] = Date.today.month
      date_form[:year]  = Date.today.year
    else
      date_form[:day]   = date[8..9]
      date_form[:month] = date[5..6]
      date_form[:year]  = date[0..3]
    end
    date_form
  end
  
  def title(selected)
    content_for(:title) { selected }
  end
end
