unless Rails.env.test?
  ActiveSupport.on_load :active_record do
    module ActiveRecord::ConnectionAdapters

      class AbstractMysqlAdapter
        def create_table_with_innodb_row_format(table_name, options = {})
          if options[:options].present?
            abort "options을 지정할 수 없습니다. 마이그레이션을 중단합니다."
          end
          table_options = options.merge(:options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC')
          create_table_without_innodb_row_format(table_name, table_options) do |td|
            yield td if block_given?
          end
        end
        alias_method_chain :create_table, :innodb_row_format
      end

    end
  end
end
