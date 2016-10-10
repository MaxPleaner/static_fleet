
# Connects to database.
# In 'production', connects to the running postgres server
# In development, it connects to a Sqlite3 database file
# A "production environment" is defined as one where ENV["DATABASE_URL"] is set.
class Database
  
  # Connect to the database
  # @return [Nil]
  def self.connect!
    is_production? ? connect_production_db! : connect_dev_db!
    Models.run_migrations!
  end
  
# -------------------------------------------------------
  private

    # Checks if the app is in production mode
    # @return [Boolean]
    def self.is_production?
      !!ENV["DATABASE_URL"]
    end
    
    # Connects ActiveRecord, given database spec as argument(s)
    # @return [Nil]
    def self.active_record_connect!(*args)
      ActiveRecord::Base.establish_connection(*args)
      nil
    end
    
    # Creates a SQLite connection to a db file.
    # @return [String] database path
    def self.build_sqlite_path
      "./lib/database/database.sqlite".tap { |path| SQLite3::Database.new(path) }
    end
    
    # Connects active record to SQLite
    # @return [Nil]
    def self.connect_dev_db!
      active_record_connect!(adapter: "sqlite3", database: build_sqlite_path)
    end
    
    # Connects active record to postgres
    # @return [Nil]
    def self.connect_production_db!
      active_record_connect!(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
    end
# -------------------------------------------------------

end
