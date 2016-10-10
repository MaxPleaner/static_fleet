# After the Sinatra route received params, it passes them off to CommandRunner for parsing.
module CommandRunner
  
  # A set of accepted params.
  # The keys are the 'main commands'. One of these strings should be provided as a parm key;
  #   the value is ignored
  # The values are 'auxiliary params' which are required
  # The result of get_command will exclude any given parameters that aren't whitelisted here.
  CommandSets = {
    'list_scripts' => [],
    'show_script' => [:id],
    'create_script' => [:name, :category, :content],
    'delete_script' => [:id],
    'update_script' => [:id, :name, :content],
    'run_script' => [:id],
    'create_site' => [:sitename],
    'get_site' => [:sitename],
    'get_file_or_dir' => [:path],
    'update_file' => [:path, :text],
    'build_site' => [:sitename],
    'deploy_site' => [:sitename],
    'add_page' => [:path, :sitename],
    'remove_page' => [:path, :sitename],
    'build_empty_site' => [:sitename],
    'build_empty_site_with_genrb' => [:sitename],
    'delete_site' => [:sitename]
  }
  
  # Look into CommandSets to determine the first matching command for the given params
  # @param given_params [Hash]
  # @return [Hash]
  def get_command(given_params)
    given_params[:sitename] && sanitize_sitename_param!(given_params)
    matches = CommandSets.reduce([]) do |results, (main_param, aux_params)|
      match_obj = { 'main_command' => given_params.has_key?(main_param) ? main_param : nil }
      aux_params.each { |param| match_obj[param] = given_params[param] }
      match_obj = match_obj.select { |k, v| k.in? (['main_command'] + aux_params) }
      results.concat([match_obj])
    end
    matches.select { |hash| hash.values.all? }.shift || {}
  end
  
  # Call a command
  # Calls ScriptCrud.list_scripts if no other commands were matches
  # @param filtered_params [Hash] which is the result of passing params through get_command
  # @param session_data [Object] the current value of session[:data]
  # @return [Hash] which is returned to the Sinatra route
  def send_command(filtered_params, session_data)
    command = filtered_params.delete('main_command')&.to_sym
    filtered_params.merge!(session_data: session_data)
    result = (command && ScriptCrud.send(command, filtered_params))
    result || ScriptCrud.list_scripts
  end
  
  def sanitize_sitename_param!(given_params)
    given_params[:sitename] = given_params[:sitename].chars.map do |char|
      char =~ /[A-Za-z0-9_\-\.]/ ? char : "-"
    end.join
    if given_params[:sitename].blank?
      given_params.delete(:sitename)
    end
    given_params
  end
  
end
