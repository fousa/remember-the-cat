class RtcController < ApplicationController
def login
    @error = reset_error
    rtm = Rtm.new
    if !cookies[:rtm_auth_token].nil?
      rtm.set_cookie(cookies[:rtm_auth_token])
    end
    if rtm.authenticated?(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'])[:error]
      url = rtm.request_frob(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], "delete")
      if url[:error]
        session["error"] = url
        redirect_to :action => :index
      else
        redirect_to url
      end
    else
      redirect_to :action => :overview
    end
  end

  def callback
    @error = reset_error
    rtm = Rtm.new
    token = rtm.request_token(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], params[:frob])
    if token[:error]
      session["error"] = token
      redirect_to :action => :index
    else
      #cookies[:rtm_auth_token] = { :value => token, :domain => 'i.fousa.be', :expires => 90.days.from_now }
      cookies[:rtm_auth_token] = { :value => token, :expires => 90.days.from_now }
      redirect_to :action => :overview
    end
  end

  def refresh
    token_id = cookies[:rtm_auth_token]
    if !token_id.nil?
      expire_fragment(%r{rtm_overview_#{token_id}.*})
      redirect_to :action => "overview"
    else
      redirect_to :action => "login"
    end
  end

  def overview
    if !cookies[:rtm_list_hidden].nil?
      cookie_vars = Marshal.load(cookies[:rtm_list_hidden])
    else
      cookie_vars = nil
    end
    i = 0
    check_undo
    rtm = Rtm.new
    rtm.set_cookie(cookies[:rtm_auth_token])
    continue = true
    @token_id = cookies[:rtm_auth_token]
    if !@token_id.nil?
      if !cookies[:rtm_overview_caching].nil? && Date.today.to_s.casecmp(cookies[:rtm_overview_caching]) != 0
        expire_fragment(%r{rtm_overview_#{@token_id}.*})
      end
      unless read_fragment("rtm_overview_" + @token_id)
        cookies[:rtm_overview_caching] = { :value => Date.today.to_s, :expires => 1.days.from_now }

        lists = Array.new
        if cookie_vars.nil? || "1".casecmp(cookie_vars[i]["hidden_all"]) == 0
          lists << { :name => "all", :url => "all", :type => "date", :url_type => nil }
        end
        i = i + 1
        if cookie_vars.nil? || "1".casecmp(cookie_vars[i]["hidden_overdue"]) == 0
          lists << { :name => "overdue", :url => "overdue", :type => "date", :url_type => nil }
        end
        i = i + 1
        if cookie_vars.nil? || "1".casecmp(cookie_vars[i]["hidden_today"]) == 0
          lists << { :name => "today", :url => "today", :type => "date", :url_type => nil }
        end
        i = i + 1
        if cookie_vars.nil? || "1".casecmp(cookie_vars[i]["hidden_tomorrow"]) == 0
          lists << { :name => "tomorrow", :url => "tomorrow", :type => "date", :url_type => nil }
        end
        i = i + 1
        if cookie_vars.nil? || "1".casecmp(cookie_vars[i]["hidden_this week"]) == 0
          lists << { :name => "this week", :url => "week", :type => "date", :url_type => nil }
        end
        i = i + 1
        if cookie_vars.nil? || "1".casecmp(cookie_vars[i]["hidden_never"]) == 0
          lists << { :name => "never", :url => "never", :type => "date", :url_type => nil }
        end
        i = i + 1

        all_lists = rtm.get_all_lists(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'])
        if all_lists[0].nil? && all_lists[:error]
        else
          for all in all_lists
            hidden_on = false
            if !cookie_vars.nil?
              cookie_vars.each_with_index do |var, i|
                if !var["hidden_" + all[:name].downcase].nil? && var["hidden_" + all[:name].downcase].casecmp("0") == 0
                  hidden_on = true
                  break
                end
                if !var["hidden_" + all[:name].downcase].nil? && var["hidden_" + all[:name].downcase].casecmp("1") == 0
                  hidden_on = false
                  break
                end
              end
            end
            if !hidden_on
              lists << { :name => all[:name], :url => all[:name], :type => all[:smart] ? "smart" : "list", :url_type => "list" }
            end
            i = i + 1
          end
        end

        @counts = Array.new

        for list in lists
          if continue
            count = rtm.get_count(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], list[:type].casecmp("date") != 0 ? "list" : list[:name], list[:type].casecmp("date") != 0 ? list[:name] : nil)
            count = count.instance_of?(Fixnum) ? count.to_s : count
            if count[:error]
              session["error"] = count
              continue = false
            else
              @counts << { :count => count, :list => list[:name], :url => list[:url], :type => list[:type], :url_type => list[:url_type] }
            end
          end
        end
        @counts = @counts.sort_by { |count| count[:type] }
      end

      @undo = set_undo
      @error = reset_error
    else
      redirect_to :action => "login"
    end
  end

  def edit
    if !cookies[:rtm_list_hidden].nil?
      cookie_vars = Marshal.load(cookies[:rtm_list_hidden])
    else
      cookie_vars = nil
    end
    i = 0
    check_undo
    rtm = Rtm.new
    rtm.set_cookie(cookies[:rtm_auth_token])
    continue = true
    @token_id = cookies[:rtm_auth_token]
    if !@token_id.nil?
      cookies[:rtm_overview_caching] = { :value => Date.today.to_s, :expires => 1.days.from_now }
      lists = Array.new
      lists << { :list => "all", :url => "all", :type => "date", :url_type => nil, :hidden => !(cookie_vars.nil? || cookie_vars[i]["hidden_all"].casecmp("1") == 0) }
      i = i + 1
      lists << { :list => "overdue", :url => "overdue", :type => "date", :url_type => nil, :hidden => !(cookie_vars.nil? || cookie_vars[i]["hidden_overdue"].casecmp("1") == 0) }
      i = i + 1
      lists << { :list => "today", :url => "today", :type => "date", :url_type => nil, :hidden => !(cookie_vars.nil? || cookie_vars[i]["hidden_today"].casecmp("1") == 0) }
      i = i + 1
      lists << { :list => "tomorrow", :url => "tomorrow", :type => "date", :url_type => nil, :hidden => !(cookie_vars.nil? || cookie_vars[i]["hidden_tomorrow"].casecmp("1") == 0) }
      i = i + 1
      lists << { :list => "this week", :url => "week", :type => "date", :url_type => nil, :hidden => !(cookie_vars.nil? || cookie_vars[i]["hidden_this week"].casecmp("1") == 0) }
      i = i + 1
       lists << { :list => "never", :url => "never", :type => "date", :url_type => nil, :hidden => !(cookie_vars.nil? || cookie_vars[i]["hidden_never"].casecmp("1") == 0) }
      i = i + 1
      all_lists = rtm.get_all_lists(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'])
      if all_lists[0].nil? && all_lists[:error]
      else
        for all in all_lists
          hidden_on = false
          if !cookie_vars.nil?
            cookie_vars.each_with_index do |var, i|
              if !var["hidden_" + all[:name].downcase].nil? && var["hidden_" + all[:name].downcase].casecmp("0") == 0
                hidden_on = true
                break
              end
              if !var["hidden_" + all[:name].downcase].nil? && var["hidden_" + all[:name].downcase].casecmp("1") == 0
                hidden_on = false
                break
              end
            end
          end
          lists << { :list => all[:name], :url => all[:name], :type => all[:smart] ? "smart" : "list", :url_type => "list", :hidden => hidden_on }
          i = i + 1
        end
      end
      @counts = lists
      @counts = @counts.sort_by { |count| count[:type] }

      @undo = set_undo
      @error = reset_error
    else
      redirect_to :action => "login"
    end
  end

  def edit_done
    check_undo
    rtm = Rtm.new
    rtm.set_cookie(cookies[:rtm_auth_token])
    continue = true
    token_id = cookies[:rtm_auth_token]
    if !token_id.nil?
      expire_fragment(%r{rtm_overview_#{token_id}.*})
      cookies[:rtm_overview_caching] = { :value => Date.today.to_s, :expires => 1.days.from_now }

      lists = Array.new
      lists << { :list => "all", :url => "all", :type => "date", :url_type => nil }
      lists << { :list => "overdue", :url => "overdue", :type => "date", :url_type => nil }
      lists << { :list => "today", :url => "today", :type => "date", :url_type => nil }
      lists << { :list => "tomorrow", :url => "tomorrow", :type => "date", :url_type => nil }
      lists << { :list => "this week", :url => "week", :type => "date", :url_type => nil }
      lists << { :list => "never", :url => "never", :type => "date", :url_type => nil }

      all_lists = rtm.get_all_lists(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'])
      if all_lists[0].nil? && all_lists[:error]
      else
        for all in all_lists
          lists << { :list => all[:name], :url => all[:name], :type => all[:smart] ? "smart" : "list", :url_type => "list" }
        end
      end
      lists = lists.sort_by { |list| list[:type] }
      save_list = Array.new
      for list in lists
        if !params["hidden_" + list[:list].downcase].nil?
          save_list <<  { "hidden_"+list[:list].downcase => params["hidden_" + list[:list].downcase] }
        end
      end
      cookies[:rtm_list_hidden] = { :value => Marshal.dump(save_list), :expires => 90.days.from_now }
      redirect_to :action => "overview"
    else
      redirect_to :action => "login"
    end
  end

  def status
    if !cookies[:rtm_auth_token].nil?
      check_undo
      @undo = set_undo
      @error = reset_error
      rtm = Rtm.new
      rtm.set_cookie(cookies[:rtm_auth_token])
      @tasks = rtm.get_tasks(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], params[:id], params[:list])
      if @tasks[0].nil? && @tasks[:error]
        @tasks = {}
      else
        if !params[:list].nil?
          session[:rtm_type] = params[:id]
          session[:rtm_type_list] = "list"
        else
          session[:rtm_type] = params[:id]
          session[:rtm_type_list] = nil
        end
        @tasks = @tasks.sort_by { |task| task[:priority] }
      end
    else
      redirect_to :action => "login"
    end
  end

  def task
    if !cookies[:rtm_auth_token].nil?
      check_undo
      @undo = set_undo
      @error = reset_error
      rtm = Rtm.new
      rtm.set_cookie(cookies[:rtm_auth_token])
      @start_date = Time.now.strftime("%Y-%m-%d")
      @task = rtm.get_task(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], params[:id])
      if @task[0].nil? && @task[:error]
        session["error"] = @task
        redirect_to :action => :status, :list => session[:rtm_type_list], :id => session[:rtm_type]
      else
        @locations = rtm.get_locations(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'])
        if @locations[0].nil? && @locations[:error]
          session["error"] = @locations
          redirect_to :action => :status, :list => session[:rtm_type_list], :id => session[:rtm_type]
        else
          session[:rtm_cur_task] = params[:id]
          session[:rtm_cur_taskseries] = @task[:taskseries_id]
          session[:rtm_cur_list] = @task[:list_id]
        end
      end
    else
      redirect_to :action => "login"
    end
  end

  def postpone
    rtm = Rtm.new
    rtm.set_cookie(cookies[:rtm_auth_token])
    @task = rtm.postpone(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], session[:rtm_cur_task], session[:rtm_cur_taskseries], session[:rtm_cur_list])
    if @task[0].nil? && @task[:error]
      session["error"] = @task
    else
      arr = Array.new
      arr << @task[:trans_id]
      session["undo"] = Undo.initialize(arr, @task[:timeline], "delay", false)
      session["undo_count"] = "2"
    end
    expire_fragment(%r{rtm_overview_#{cookies[:rtm_auth_token]}.*})
    redirect_to :controller => :rtc, :action => :task, :id => session[:rtm_cur_task]
  end

  def delete
    rtm = Rtm.new
    rtm.set_cookie(cookies[:rtm_auth_token])
    @task = rtm.delete(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], session[:rtm_cur_task], session[:rtm_cur_taskseries], session[:rtm_cur_list])
    if @task[0].nil? && @task[:error]
      session["error"] = @task
    else
      arr = Array.new
      arr << @task[:trans_id]
      session["undo"] = Undo.initialize(arr, @task[:timeline], "delete", false)
      session["undo_count"] = "2"
    end
    expire_fragment(%r{rtm_overview_#{cookies[:rtm_auth_token]}.*})
    redirect_to :controller => :rtc, :action => :status, :list => session[:rtm_type_list], :id => session[:rtm_type]
  end

  def complete
    rtm = Rtm.new
    rtm.set_cookie(cookies[:rtm_auth_token])
    @task = rtm.complete(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], session[:rtm_cur_task], session[:rtm_cur_taskseries], session[:rtm_cur_list])
    if @task[0].nil? && @task[:error]
      session["error"] = @task
    else
      arr = Array.new
      arr << @task[:trans_id]
      session["undo"] = Undo.initialize(arr, @task[:timeline], "complete", false)
      session["undo_count"] = "2"
    end
    expire_fragment(%r{rtm_overview_#{cookies[:rtm_auth_token]}.*})
    redirect_to :controller => :rtc, :action => :status, :list => session[:rtm_type_list], :id => session[:rtm_type]
  end

  def undo
    rtm = Rtm.new
    rtm.set_cookie(cookies[:rtm_auth_token])
    if set_undo[:delete]
      tmp = set_undo[:delete]
      @task = rtm.delete(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], tmp[:id], tmp[:taskseries_id], tmp[:list_id])
    else
      for element in set_undo[:trans_id]
        @task = rtm.undo(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], element, set_undo[:timeline])
      end
    end
    if @task[0].nil? && @task[:error]
      session["error"] = @task
    else
      session["undo"] = nil
    end
    expire_fragment(%r{rtm_overview_#{cookies[:rtm_auth_token]}.*})
    redirect_to request.env["HTTP_REFERER"]
  end

  def update
    rtm = Rtm.new
    rtm.set_cookie(cookies[:rtm_auth_token])
    continue = true
    arr = Array.new
    @task_name = rtm.set_name(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], session[:rtm_cur_task], session[:rtm_cur_taskseries], session[:rtm_cur_list], params[:name])
    if @task_name[:error]
      session["error"] = @task_name
      continue = false
    else
      arr << @task_name[:trans_id]
    end
    if continue
      @task_priority = rtm.set_priority(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], session[:rtm_cur_task], session[:rtm_cur_taskseries], session[:rtm_cur_list], params[:priority], @task_name[:timeline])
      if @task_priority[:error]
        session["error"] = @task_priority
        continue = false
      else
        arr << @task_priority[:trans_id]
      end
    end
    if continue
      if !params[:due_none].nil?
        date = ""
      else
        date = params[:date]
      end
      @task_due = rtm.set_due(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], session[:rtm_cur_task], session[:rtm_cur_taskseries], session[:rtm_cur_list], date, @task_name[:timeline])
      if @task_due[:error]
        session["error"] = @task_due
        continue = false
      else
        arr << @task_due[:trans_id]
      end
    end
    if continue
      @task_location = rtm.set_location(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], session[:rtm_cur_task], session[:rtm_cur_taskseries], session[:rtm_cur_list], params[:location], @task_name[:timeline])
      if @task_location[:error]
        session["error"] = @task_location
        continue = false
      else
        arr << @task_location[:trans_id]
      end
    end
    if continue
      @task_url = rtm.set_url(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], session[:rtm_cur_task], session[:rtm_cur_taskseries], session[:rtm_cur_list], params[:url], @task_name[:timeline])
      if @task_url[:error]
        session["error"] = @task_url
        continue = false
      else
        arr << @task_url[:trans_id]
      end
    end
    if continue
      @task_tags = rtm.set_tags(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], session[:rtm_cur_task], session[:rtm_cur_taskseries], session[:rtm_cur_list], params[:tags], @task_name[:timeline])
      if @task_tags[:error]
        session["error"] = @task_tags
        continue = false
      else
        arr << @task_tags[:trans_id]
      end
    end
    if arr.size > 0
      session["undo"] = Undo.initialize(arr, @task_name[:timeline], "update", false)
      session["undo_count"] = "2"
    end
    expire_fragment(%r{rtm_overview_#{cookies[:rtm_auth_token]}.*})
    redirect_to :controller => :rtc, :action => :task, :id => session[:rtm_cur_task]
  end

  def add
    check_undo
    @undo = set_undo
    @error = reset_error
    rtm = Rtm.new
    rtm.set_cookie(cookies[:rtm_auth_token])
    continue = true
    @locations = rtm.get_locations(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'])
    if @locations[0].nil? && @locations[:error]
      session["error"] = @locations
      continue = false
    end
    if continue
      @lists = rtm.get_lists(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'])
      if @lists[0].nil? && @lists[:error]
        session["error"] = @lists
        continue = false
      end
    end
    @task = nil
    @start_date = nil
    @start_list = params[:id]
    delete = nil
    if !params.nil? && !params[:commit].nil? && params[:commit].casecmp("add") == 0 && continue
      if params[:name].casecmp("") == 0
        @task_name = Error::initialize("A name for the task is missing")
        session["error"] = @task_name
        continue = false
      else
        @task_name = rtm.add(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], params[:name], params[:list])
        if @task_name[:error]
          session["error"] = @task_name
          continue = false
        else
          delete = { :id => @task_name[:id], :taskseries_id => @task_name[:taskseries_id], :list_id => @task_name[:list_id] }
          @task = { :name => @task_name[:name], :list => params[:list], :priority => "", :url => "", :due => "", :location => "", :tags => Array.new }
        end
      end
      if continue
        @task_priority = rtm.set_priority(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], @task_name[:id], @task_name[:taskseries_id], @task_name[:list_id], params[:priority], @task_name[:timeline])
        if @task_priority[:error]
          session["error"] = @task_priority
          continue = false
        else
          @task[:priority] = params[:priority]
        end
      end
      if continue && params[:due_none].nil?
        @task_due = rtm.set_due(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], @task_name[:id], @task_name[:taskseries_id], @task_name[:list_id], params[:date], @task_name[:timeline])
        if @task_due[:error]
          session["error"] = @task_due
          continue = false
        else
          @task[:due] = params[:date][:year] + "-" + params[:date][:month] + "-" + params[:date][:day]
        end
      end
      if continue && params[:location].casecmp("") != 0
        @task_location = rtm.set_location(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], @task_name[:id], @task_name[:taskseries_id], @task_name[:list_id], params[:location], @task_name[:timeline])
        if @task_location[:error]
          session["error"] = @task_location
          continue = false
        else
          @task[:location] = params[:location]
        end
      end
      if continue && params[:url].casecmp("") != 0
        @task_url = rtm.set_url(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], @task_name[:id], @task_name[:taskseries_id], @task_name[:list_id], params[:url], @task_name[:timeline])
        if @task_url[:error]
          session["error"] = @task_url
          continue = false
        else
          @task[:url] = params[:url]
        end
      end
      if continue && params[:tags].casecmp("") != 0
        @task_tags = rtm.set_tags(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], @task_name[:id], @task_name[:taskseries_id], @task_name[:list_id], params[:tags], @task_name[:timeline])
        if @task_tags[:error]
          session["error"] = @task_tags
          continue = false
        else
          @task[:tags] = params[:tags]
        end
      end
      if !continue
        if !@task_name[:error]
          @task_del = rtm.delete(CONFIG['rememberthemilk']['api_key'], CONFIG['rememberthemilk']['secret'], @task_name[:id], @task_name[:taskseries_id], @task_name[:list_id])
        end
      end
      if !delete.nil? && continue
        session["undo"] = Undo.initialize("", @task_name[:timeline], "add", delete)
        session["undo_count"] = "2"
        @task = nil
        @undo = set_undo
      end
      expire_fragment(%r{rtm_overview_#{cookies[:rtm_auth_token]}.*})
    end
    if params[:id].casecmp("today") == 0
  		@start_date = Time.now.strftime("%Y-%m-%d")
  	elsif params[:id].casecmp("tomorrow") == 0
  		@start_date = (Time.now+1.day).strftime("%Y-%m-%d")
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

  def set_undo
    session["undo"]
  end

  def check_undo
    if session["undo_count"].nil? || session["undo_count"] == 0
      session["undo"] = nil
    else
      session["undo_count"] = session["undo_count"].to_i - 1
    end
  end
end