class MainController < ApplicationController
  def index
    @error = reset_error
    session["undo"] = nil
  end
  
  def policy
    @error = reset_error
    session["undo"] = nil
  end
  
  def feedback
    session["undo"] = nil
    if !params.nil? && !params[:commit].nil?
      if params[:feedback].casecmp("") != 0
        FousaMailer.deliver_feedback(params[:application] ,params[:feedback])
        @succes = true
      else
        session["error"] = Error::initialize("There was no feedback available in the textfield.")
      end
    end
    @error = reset_error
  end
  
  ######################################################################### PRIVATE ACTIONS ####################################
  
  private
  
  def reset_error
    error = session["error"]
    session["error"] = nil
    error
  end
end
