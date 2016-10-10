# Some helpers for Sinatra routes
module SinatraUtils
  
  # Copies each key-val of an hash into a route's instance variables
  # The instance variables are accessible to views
  # @param [Hash]
  # @return [Nil]
  def copy_object_to_ivars(hash)
    hash.is_a?(Hash) && hash.each { |k,v| instance_variable_set("@#{k}", v) }
    nil
  end
  
  # Copies each key-val of a hash into a request's flash
  # The flash persists across a single redirect
  # @param [Hash]
  # @return [Nil]
  def copy_object_to_flash(hash)
    hash.is_a?(Hash) && hash.each { |k,v| flash[k] = v }
    nil
  end
  
  # Copies each key-val of a hash into a request's session
  # @param [Hash]
  # @return [Nil]
  def copy_object_to_session(hash)
    flash['session'] ||= {}
    hash.is_a?(Hash) && hash.each { |k,v| flash['session'][k] = v }
    persist_session!
    nil
  end
  
  # Makes the session persist for one more request.
  def persist_session!
    # using flash[]= persists the key for one more request
    # without doing this, the session key will expire
    flash['session'] = flash['session']
  end

end