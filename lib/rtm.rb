#!/usr/bin/env ruby

class Rtm
  AUTH_URL = "http://www.rememberthemilk.com/services/auth/?"
  API_URL = "http://www.rememberthemilk.com/services/rest/?"
  
  attr_accessor :auth_cookie
  
  def set_cookie(cookie)
    @auth_cookie = cookie
  end
  
  # Checks if the token is valid
  def authenticated?(api_key, secret)
    check_token(api_key, secret, check_local_token)
  end
  
    ######################################################################### READ ACTIONS ####################################
  
  # Generates the authentication url
  def request_frob(api_key, secret, perms)
    begin
      args            = {}
      args['api_key'] = api_key
      args['perms']   = perms
      args['api_sig'] = generate_signature(args, secret)
    
		  AUTH_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
		rescue
		  Error::initialize("An error occured while generating the authentication url")
	  end
  end
  
  # Requests the token from rtm
  def request_token(api_key, secret, frob, token_cache='xml/rtm.xml')
    begin
      args            = {}
      args['api_key'] = api_key
      args['frob']    = frob
      args['method']  = "rtm.auth.getToken"
      args['api_sig'] = generate_signature(args, secret)
    
      require 'open-uri'
      url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
      open(url) do |http|
        doc = REXML::Document.new(http.read)
        doc.elements.each('rsp/auth/token') { |e| e.text }[0].text
      end
    rescue
      Error::initialize("An error occured while requesting a token")
    end
  end
  
  # Gets the number of tasks that er incomplete and with the filter on type
  def get_count(api_key, secret, type="all", list=nil)
    if check_local_token != false
      begin
        args               = {}
        args['api_key']    = api_key
        args['auth_token'] = check_local_token
        args['method']     = "rtm.tasks.getList"
        if type.casecmp('overdue') == 0
          args['filter']   = "dueBefore:today AND status:incomplete"
        elsif type.casecmp('today') == 0
          args['filter']   = "due:today AND status:incomplete"
        elsif type.casecmp('tomorrow') == 0
          args['filter']   = "due:tomorrow AND status:incomplete"
        elsif type.casecmp('never') == 0
          args['filter']   = "due:never AND status:incomplete"
        elsif type.casecmp('this week') == 0
          args['filter']   = "dueWithin:\"1 week of today\" AND status:incomplete"
        elsif type.casecmp('list') == 0 && !list.nil?
          args['filter']   = "list:\"" + list + "\" AND status:incomplete"
        else
          args['filter']   = "status:incomplete"
        end
        args['api_sig']    = generate_signature(args, secret)
        args['filter']     = CGI::escape(args['filter'])
        require 'open-uri'
        url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
        open(url) do |http|
          doc = REXML::Document.new(http.read)
          count = 0
          doc.elements.each('rsp/tasks/list/taskseries/task') {|e|
            count = count + 1
          }
          count
        end
      rescue
        Error::initialize("An error occured while fetching the count of the tasks that belong to the type " + type)
      end
    else
      Error::initialize("An error occured while fetching the count of the tasks that belong to the type " + type)
    end
  end
  
  # Fetches all the lists
  def get_all_lists(api_key, secret)
    if check_local_token != false
      begin
        args               = {}
         args['api_key']    = api_key
         args['auth_token'] = check_local_token
         args['method']     = "rtm.lists.getList"
         args['api_sig']    = generate_signature(args, secret)
         require 'open-uri'
         url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
         open(url) do |http|
           doc = REXML::Document.new(http.read)
           lists = Array.new
           doc.elements.each('rsp/lists/list') {|e|
             lists << { :name => e.attributes['name'], :id => e.attributes['id'], :smart => e.attributes['smart'].casecmp("1") == 0 }
           }
           lists
         end
      rescue
        Error::initialize("An error occured while fetching your lists")
      end
    else
      Error::initialize("An error occured while fetching your lists")
    end
  end
  
  # Gets all the incomplete tasks with a certain type
  def get_tasks(api_key, secret, type="all", list=nil)
    if check_local_token != false
      begin
        args               = {}
        args['api_key']    = api_key
        args['auth_token'] = check_local_token
        args['method']     = "rtm.tasks.getList"
        if !list.nil?
          args['filter']   = "list:\"#{type}\" AND status:incomplete"
        else
          if type.casecmp('overdue') == 0
            args['filter']   = "dueBefore:today AND status:incomplete"
          elsif type.casecmp('today') == 0
            args['filter']   = "due:today AND status:incomplete"
          elsif type.casecmp('tomorrow') == 0
            args['filter']   = "due:tomorrow AND status:incomplete"
          elsif type.casecmp('never') == 0
            args['filter']   = "due:never AND status:incomplete"
          elsif type.casecmp('week') == 0
            args['filter']   = "dueWithin:\"1 week of today\" AND status:incomplete"
          else
            args['filter']   = "status:incomplete"
          end
        end
        args['api_sig']    = generate_signature(args, secret)
        args['filter']     = CGI::escape(args['filter'])
        require 'open-uri'
        url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
        open(url) do |http|
          doc = REXML::Document.new(http.read)
          tasks = Array.new
          doc.elements.each('rsp/tasks/list/taskseries') {|e|
            tasks << { :name => e.attributes['name'], :priority => e.elements['task'].attributes['priority'], :id => e.elements['task'].attributes['id'] }
          }
          if tasks.length == 0
            Error::initialize("There were no incomplete tasks found for the type " + type)
          else
            tasks
          end
        end
      rescue
        Error::initialize("An error occured while fetching a list of tasks belonging to the type " + type)
      end
    else
      Error::initialize("An error occured while fetching a list of tasks belonging to the type " + type)
    end
  end
  
  # Gets a task
  def get_task(api_key, secret, id)
    if check_local_token != false
      begin
        args               = {}
        args['api_key']    = api_key
        args['auth_token'] = check_local_token
        args['method']     = "rtm.tasks.getList"
        args['filter']     = "status:incomplete"
        args['api_sig']    = generate_signature(args, secret)
        require 'open-uri'
        url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
        open(url) do |http|
          task = nil
          doc = REXML::Document.new(http.read)
          doc.elements.each('rsp/tasks/list/taskseries') {|e|
            e.elements.each('task') {|p|
              if p.attributes['id'].casecmp(id) == 0
                tags = Array.new
                e.elements.each("tags/tag") { |t|
                  tags << t.text
                }
                task = { :url => e.attributes['url'],:name => e.attributes['name'], :priority => p.attributes['priority'], :id => p.attributes['id'], :due => p.attributes['due'], :location => e.attributes['location_id'], :postponed => p.attributes['postponed'], :taskseries_id => e.attributes['id'], :list_id => e.parent.attributes['id'], :tags => tags }
                break
              end
            }
          }
          if task.nil?
            Error::initialize("There was no incomplete task found with id " + id)
          else
            task
          end
        end
      rescue
        Error::initialize("An error occured while fetching a tasks with id " + id)
      end
    else
      Error::initialize("An error occured while fetching a tasks with id " + id)
    end
  end
  
  # Fetches all the locations
  def get_locations(api_key, secret)
    if check_local_token != false
      begin
        args               = {}
         args['api_key']    = api_key
         args['auth_token'] = check_local_token
         args['method']     = "rtm.locations.getList"
         args['api_sig']    = generate_signature(args, secret)
         require 'open-uri'
         url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
         open(url) do |http|
           doc = REXML::Document.new(http.read)
           locations = Array.new
           doc.elements.each('rsp/locations/location') {|e|
               locations << { :name => e.attributes['name'], :id => e.attributes['id'], :lat => e.attributes['latitude'], :lon => e.attributes['longitude'] }
           }
           if locations.size == 0
             locations = {}
           else
             locations
           end
         end
      rescue
        Error::initialize("An error occured while fetching your locations")
      end
    else
      Error::initialize("An error occured while fetching your locations")
    end
  end
  
  # Fetches all the lists
  def get_lists(api_key, secret)
    if check_local_token != false
      begin
        args               = {}
         args['api_key']    = api_key
         args['auth_token'] = check_local_token
         args['method']     = "rtm.lists.getList"
         args['api_sig']    = generate_signature(args, secret)
         require 'open-uri'
         url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
         open(url) do |http|
           doc = REXML::Document.new(http.read)
           lists = Array.new
           doc.elements.each('rsp/lists/list') {|e|
             if e.attributes['smart'].casecmp("0") == 0
               lists << { :name => e.attributes['name'], :id => e.attributes['id'] }
             end
           }
           lists
         end
      rescue
        Error::initialize("An error occured while fetching your lists")
      end
    else
      Error::initialize("An error occured while fetching your lists")
    end
  end
  
    ######################################################################### WRITE ACTIONS ####################################
  
  def undo(api_key, secret, trans_id, timeline)
    if check_local_token != false
      begin
        args                  = {}
        args['api_key']       = api_key
        args['auth_token']    = check_local_token
        args['method']        = "rtm.transactions.undo"
        args['timeline']      = timeline
        args['transaction_id']= trans_id
        args['api_sig']       = generate_signature(args, secret)
        if set_value_no(args)
          {}
        else
          Error::initialize("An error occured while undoing an action with id " + trans_id)
        end
      rescue
        Error::initialize("An error occured while undoing an action with id " + trans_id)
      end
    else
      Error::initialize("An error occured while undoing an action with id " + trans_id)
    end
  end
    
  def postpone(api_key, secret, id, taskseries_id, list_id)
    if check_local_token != false
      begin
        timeline = get_timeline(api_key, secret, check_local_token)
        if timeline[:error]
          timeline
        else
          args                  = {}
          args['api_key']       = api_key
          args['auth_token']    = check_local_token
          args['method']        = "rtm.tasks.postpone"
          args['timeline']      = timeline
          args['task_id']       = id
          args['taskseries_id'] = taskseries_id
          args['list_id']       = list_id
          args['api_sig']       = generate_signature(args, secret)
          trans_id = set_value(args)
          if trans_id
            { :timeline => timeline, :trans_id => trans_id }
          else
            Error::initialize("An error occured while postponing a task with id " + id)
          end
        end
      rescue
        Error::initialize("An error occured while postponing a task with id " + id)
      end
    else
      Error::initialize("An error occured while postponing a task with id " + id)
    end
  end
   
  def delete(api_key, secret, id, taskseries_id, list_id)
    if check_local_token != false
      begin
        timeline = get_timeline(api_key, secret, check_local_token)
        if timeline[:error]
          timeline
        else
          args                  = {}
          args['api_key']       = api_key
          args['auth_token']    = check_local_token
          args['method']        = "rtm.tasks.delete"
          args['timeline']      = timeline
          args['task_id']       = id
          args['taskseries_id'] = taskseries_id
          args['list_id']       = list_id
          args['api_sig']       = generate_signature(args, secret)
          trans_id = set_value(args)
          if trans_id
            { :timeline => timeline, :trans_id => trans_id }
          else
            Error::initialize("An error occured while deleting a task with id " + id)
          end
        end
      rescue
        Error::initialize("An error occured while deleting a task with id " + id)
      end
    else
      Error::initialize("An error occured while deleting a task with id " + id)
    end
  end
   
  def complete(api_key, secret, id, taskseries_id, list_id)
    if check_local_token != false
      begin
        timeline = get_timeline(api_key, secret, check_local_token)
        if timeline[:error]
          timeline
        else
          args                  = {}
          args['api_key']       = api_key
          args['auth_token']    = check_local_token
          args['method']        = "rtm.tasks.complete"
          args['timeline']      = timeline
          args['task_id']       = id
          args['taskseries_id'] = taskseries_id
          args['list_id']       = list_id
          args['api_sig']       = generate_signature(args, secret)
          trans_id = set_value(args)
          if trans_id
            { :timeline => timeline, :trans_id => trans_id }
          else
            Error::initialize("An error occured while completing a task with id " + id)
          end
        end
      rescue
        Error::initialize("An error occured while completing a task with id " + id)
      end
    else
      Error::initialize("An error occured while completing a task with id " + id)
    end
  end
  
  def set_name(api_key, secret, id, taskseries_id, list_id, name)
    if check_local_token != false
      begin
        timeline = get_timeline(api_key, secret, check_local_token)
        if timeline[:error]
          timeline
        else
          args                   = {}
          args['api_key']        = api_key
          args['auth_token']     = check_local_token
          args['method']         = "rtm.tasks.setName"
          args['timeline']       = timeline
          args['task_id']        = id
          args['taskseries_id']  = taskseries_id
          args['list_id']        = list_id
          args['name']           = name
          args['api_sig']        = generate_signature(args, secret)
          args['name']           = CGI::escape(name)
          trans_id = set_value(args)
          if trans_id
            { :timeline => timeline, :trans_id => trans_id }
          else
            Error::initialize("An error occured while editing the name for a task with id " + id)
          end
        end
      rescue
        Error::initialize("An error occured while editing the name for a task with id " + id)
      end
    else
      Error::initialize("An error occured while editing the name for a task with id " + id)
    end
  end
  
  def set_url(api_key, secret, id, taskseries_id, list_id, url, timeline_tmp=nil)
    if check_local_token != false
      begin
        if timeline_tmp.nil?
          timeline = get_timeline(api_key, secret, check_local_token)
        else
          timeline = timeline_tmp
        end
        if timeline[:error]
          timeline
        else
          args                   = {}
          args['api_key']        = api_key
          args['auth_token']     = check_local_token
          args['method']         = "rtm.tasks.setURL"
          args['timeline']       = timeline
          args['task_id']        = id
          args['taskseries_id']  = taskseries_id
          args['list_id']        = list_id
          args['url']            = url
          args['api_sig']        = generate_signature(args, secret)
          args['url']           = CGI::escape(url)
          trans_id = set_value(args)
          if trans_id
            { :timeline => timeline, :trans_id => trans_id }
          else
            Error::initialize("An error occured while editing the url for a task with id " + id)
          end
        end
      rescue
        Error::initialize("An error occured while editing the url for a task with id " + id)
      end
    else
      Error::initialize("An error occured while editing the url for a task with id " + id)
    end
  end
  
  def set_priority(api_key, secret, id, taskseries_id, list_id, priority, timeline_tmp=nil)
    if check_local_token != false
      begin
        if timeline_tmp.nil?
          timeline = get_timeline(api_key, secret, check_local_token)
        else
          timeline = timeline_tmp
        end
        if timeline[:error]
          timeline
        else
          args                  = {}
          args['api_key']       = api_key
          args['auth_token']    = check_local_token
          args['method']        = "rtm.tasks.setPriority"
          args['timeline']      = timeline
          args['task_id']       = id
          args['taskseries_id'] = taskseries_id
          args['list_id']       = list_id
          args['priority']      = priority
          args['api_sig']       = generate_signature(args, secret)
          trans_id = set_value(args)
          if trans_id
            { :timeline => timeline, :trans_id => trans_id }
          else
            Error::initialize("An error occured while editing the priority for a task with id " + id)
          end
        end
      rescue
        Error::initialize("An error occured while editing the priority for a task with id " + id)
      end
    else
      Error::initialize("An error occured while editing the priority for a task with id " + id)
    end
  end
  
  def set_location(api_key, secret, id, taskseries_id, list_id, location, timeline_tmp=nil)
    if check_local_token != false
      begin
        if timeline_tmp.nil?
          timeline = get_timeline(api_key, secret, check_local_token)
        else
          timeline = timeline_tmp
        end
        if timeline[:error]
          timeline
        else
          args                  = {}
          args['api_key']       = api_key
          args['auth_token']    = check_local_token
          args['method']        = "rtm.tasks.setLocation"
          args['timeline']      = timeline
          args['task_id']       = id
          args['taskseries_id'] = taskseries_id
          args['list_id']       = list_id
          args['location_id']   = location
          args['api_sig']       = generate_signature(args, secret)
          trans_id = set_value(args)
          if trans_id
            { :timeline => timeline, :trans_id => trans_id }
          else
            Error::initialize("An error occured while editing the locations for a task with id " + id)
          end
        end
      rescue
        Error::initialize("An error occured while editing the locations for a task with id " + id)
      end
    else
      Error::initialize("An error occured while editing the locations for a task with id " + id)
    end
  end
  
  def set_due(api_key, secret, id, taskseries_id, list_id, date, timeline_tmp=nil)
    if check_local_token != false
      begin
        if timeline_tmp.nil?
          timeline = get_timeline(api_key, secret, check_local_token)
        else
          timeline = timeline_tmp
        end
        if timeline[:error]
          timeline
        else
          args                  = {}
          args['api_key']       = api_key
          args['auth_token']    = check_local_token
          args['method']        = "rtm.tasks.setDueDate"
          args['timeline']      = timeline
          args['task_id']       = id
          args['taskseries_id'] = taskseries_id
          args['list_id']       = list_id
          if !date.instance_of?(String)
            args['due']           = date[:year] + "-" + date[:month] + "-" + date[:day] + "T12:34:56Z"
          end
          args['api_sig']       = generate_signature(args, secret)
          trans_id = set_value(args)
          if trans_id
            { :timeline => timeline, :trans_id => trans_id }
          else
            Error::initialize("An error occured while editing the due date for a task with id " + id)
          end
        end
      rescue
        Error::initialize("An error occured while editing the due date for a task with id " + id)
      end
    else
      Error::initialize("An error occured while editing the due date for a task with id " + id)
    end
  end
  
  def set_tags(api_key, secret, id, taskseries_id, list_id, tags, timeline_tmp=nil)
    if check_local_token != false
      begin
        if timeline_tmp.nil?
          timeline = get_timeline(api_key, secret, check_local_token)
        else
          timeline = timeline_tmp
        end
        if timeline[:error]
          timeline
        else
          args                  = {}
          args['api_key']       = api_key
          args['auth_token']    = check_local_token
          args['method']        = "rtm.tasks.setTags"
          args['timeline']      = timeline
          args['task_id']       = id
          args['taskseries_id'] = taskseries_id
          args['list_id']       = list_id
          args['tags']          = tags
          args['api_sig']       = generate_signature(args, secret)
          args['tags']          = CGI::escape(tags)
          trans_id = set_value(args)
          if trans_id
            { :timeline => timeline, :trans_id => trans_id }
          else
            Error::initialize("An error occured while editing tags for a task with id " + id)
          end
        end
      rescue
        Error::initialize("An error occured while editing tags for a task with id " + id)
      end
    else
      Error::initialize("An error occured while editing tags for a task with id " + id)
    end
  end
  
  def add(api_key, secret, name, list_id)
    if check_local_token != false
      begin
        timeline = get_timeline(api_key, secret, check_local_token)
        if timeline[:error]
          timeline
        else
          args                  = {}
          args['api_key']       = api_key
          args['auth_token']    = check_local_token
          args['method']        = "rtm.tasks.add"
          args['timeline']      = timeline
          if list_id.casecmp("") != 0
            args['list_id']       = list_id
          end
          args['name']          = name
          args['api_sig']       = generate_signature(args, secret)
          args['name']          = CGI::escape(name)
          id_values = set_value_with_ids(args)
          if id_values
            { :timeline => timeline, :name => id_values[:name], :priority => id_values[:priority], :id => id_values[:id], :taskseries_id => id_values[:taskseries_id], :list_id => id_values[:list_id], :trans_id => id_values[:trans_id] }
          else
            Error::initialize("An error occured while adding a task")
          end
        end
      rescue
        Error::initialize("An error occured while adding a task")
      end
    else
      Error::initialize("An error occured while adding a task")
    end
  end
  
  ######################################################################### PRIVATE ####################################
  
  private
  
  def generate_signature(args, secret)
    require 'md5'
    MD5.md5(secret + args.sort.flatten.join).to_s
  end
  
  def check_local_token
    @auth_cookie
  end
  
  #checks the validity of the token
  def check_token(api_key, secret, token)
    begin
      args = {}
      args['api_key']    = api_key
      args['auth_token'] = token
      args['method']     = "rtm.auth.checkToken"
      args['api_sig']    = generate_signature(args, secret)
  
      require 'open-uri'
      url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
      open(url) do |http|
        doc = REXML::Document.new(http.read)
        token = doc.elements.each('rsp/auth/user') { |e| e.text }[0].attributes
      end
    rescue
      Error::initialize("An error occured while checkin the validity of the token")
    end
  end
  
  # fetches the timeline
  def get_timeline(api_key, secret, token)
    begin
      args               = {}
      args['api_key']    = api_key
      args['auth_token'] = check_local_token
      args['method']     = "rtm.timelines.create"
      args['api_sig']    = generate_signature(args, secret)
      require 'open-uri'
      url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
      open(url) do |http|
        begin
           doc = REXML::Document.new(http.read)
           timeline = ""
           doc.elements.each('rsp/timeline') {|e|
             timeline = e.text
           }
           timeline
         end
      end
    rescue
      Error::initialize("An error occured while generating the timeline")
    end
  end
  
  def set_value(args)
    require 'open-uri'
    url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
    open(url) do |http|
      doc = REXML::Document.new(http.read)
      doc.elements.each('rsp/transaction') {|e|
         @trans_id = e.attributes['id']
      }
      return @trans_id
    end
    false
  end
  
  def set_value_no(args)
    require 'open-uri'
    url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
    open(url) do |http|
      doc = REXML::Document.new(http.read)
      return true
    end
    false
  end
  
  def set_value_with_ids(args)
    require 'open-uri'
    url = API_URL + args.to_a.map{|arr| arr.join('=')}.join('&')
    open(url) do |http|
      doc = REXML::Document.new(http.read)
      doc.elements.each('rsp/list') {|e|
         @list_id = e.attributes['id']
       }
       doc.elements.each('rsp/transaction') {|e|
          @trans_id = e.attributes['id']
       }
      doc.elements.each('rsp/list/taskseries') {|e|
        @ids = { :name => e.attributes['name'], :priority => e.elements['task'].attributes['priority'], :id => e.elements['task'].attributes['id'], :taskseries_id => e.attributes['id'], :list_id => @list_id, :trans_id => @trans_id }
      }
      return @ids
    end
    false
  end
end