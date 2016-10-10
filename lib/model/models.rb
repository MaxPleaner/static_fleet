# -----------
# IMPORTANT: require the individua model files from main.rb, not here
# -----------

# Syncs app state with database by running migrations
class Models

  # Run all migrations (unless they've already been run)
  # @return [Nil]
  def self.run_migrations!
    [
      SavedScript
    ].each { |klass| create_table_unless_it_exists(klass) }
    nil
  end
  
  private
  
  # Given an ActiveRecord::Migration class, run the migration and rescue 'already run' errors.
  # @return [Nil]
  def self.create_table_unless_it_exists(klass)
    begin
      klass.migrate(:up)
    rescue ActiveRecord::StatementInvalid => e
      error_catcher_regex = /SQLite3::SQLException: table "([\w]+)" already exists/
      caught_failing_table = e.message.scan(error_catcher_regex).flatten.shift
      e.skip unless caught_failing_table
    end
    nil
  end

end

