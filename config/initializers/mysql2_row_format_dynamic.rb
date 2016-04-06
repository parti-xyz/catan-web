ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.class_eval do
    def create_table(table_name, options = {}) #:nodoc:
      super(table_name, options.reverse_merge(:options => 'ROW_FORMAT=DYNAMIC ENGINE=InnoDB'))
    end
  end
end
