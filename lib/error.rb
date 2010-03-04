#!/usr/bin/env ruby

class Error
  def self.initialize(description)
    { :error => true, :description => description }
  end
end