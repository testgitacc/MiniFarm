  require 'data_mapper' # requires all the gems listed above

  # If you want the logs displayed you have to do this before the call to setup
  DataMapper::Logger.new($stdout, :debug)


  # A MySQL connection:
  #DataMapper.setup(:default, 'mysql://localhost/the_database_name')

  # A Postgres connection:
  DataMapper.setup(:default, 'postgres://localhost/the_database_name')