#!/usr/bin/env ruby

class Undo
  def self.initialize(trans_id, timeline, description, arr)
    { :undo => true, :trans_id => trans_id, :description => description, :timeline => timeline, :delete => arr }
  end
end