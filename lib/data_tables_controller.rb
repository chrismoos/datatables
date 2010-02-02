module DataTablesController
  def self.included(cls)
    cls.extend(ClassMethods)
  end
  
  module ClassMethods
    def datatables_source(action, model, *attrs)
      modelCls = Kernel.const_get(model.to_s.capitalize)
      modelAttrs = modelCls.new.attributes
      
      columns = []
      modelAttrs.each_key { |k| columns << k }
      
      options = {}
      attrs.each do |option|
        option.each { |k,v| options[k] = v }
      end

      # override columns
      columns = options_to_columns(options) if options[:columns]
      
      # number of results
      numResults = options[:numResults].nil? ? 10 : options[:numResults]

      # define columns so they are accessible from the helper
      define_columns(modelCls, columns, action)
            
      # define method that returns the data for the table
      define_datatables_action(self, action, modelCls, columns, numResults)
    end

    def define_datatables_action(controller, action, modelCls, columns, numResults)      
      define_method action.to_sym do
        limit = params[:iDisplayLength].nil? ? numResults : params[:iDisplayLength].to_i
        
        totalRecords = modelCls.count
        data = modelCls.find(:all, :offset => params[:iDisplayStart].to_i, :limit => limit).collect do |instance|
          columns.collect { |column| datatables_instance_get_value(instance, column) }
        end
        render :text => {:iTotalRecords => totalRecords, :iTotalDisplayRecords => totalRecords,
            :aaData => data, :sEcho => params[:sEcho].to_i}.to_json
      end
    end
    
    private
    
    #
    # Takes a list of columns from options and transforms them
    #
    def options_to_columns(options)
      columns = []
      options[:columns].each do |column|
        if column.kind_of? Symbol # a column from the database, we don't need to do anything
          columns << {:name => column, :attribute => column}
        elsif column.kind_of? Hash
          columns << {:name => column[:name], :special => column}
        end
      end
      columns
    end
    
    def define_columns(cls, columns, action)
      define_method "datatable_#{action}_columns".to_sym do
        columnNames = []
        columns.each do |column|
          if column[:method] or column[:eval]
            columnNames << I18n.t(column[:name], :default => column[:name].to_s)
          else
            columnNames << I18n.t(column[:name].to_sym, :default => column[:name].to_s)
          end
        end
        columnNames
      end
    end
  end
  
  # gets the value for a column and row
  def datatables_instance_get_value(instance, column)
    if column[:attribute]
      val = instance.send(column[:attribute].to_sym)
      return I18n.t(val.to_s.to_sym, :default => val.to_s) if not val.nil?
      return ''
    elsif column[:special]
      special = column[:special]
      
      if special[:method]
        return method(special[:method].to_sym).call(instance)
      elsif special[:eval]
        proc = lambda { obj = instance; binding }
        return Kernel.eval(special[:eval], proc.call)
      end
    end
    return "value not found"
  end
  
  def datatable_source(name)
    {:action => name, :attrs => method("datatable_#{name}_columns".to_sym).call}
  end
end