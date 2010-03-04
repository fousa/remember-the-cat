class FousaMailer < ActionMailer::Base
  def feedback(application, feedback)
    recipients  "jelle@fousa.be"
    from        "Fousa For iPhone <iphone@fousa.be>"
    subject     "Feedback for #{application}"
    body        :feedback => feedback
  end
end