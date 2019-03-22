class AppModel
  def initialize(init)
    init.each_pair do |key, val|
      instance_variable_set('@' + key.to_s, val)
      instance_eval "class << self; attr_accessor :#{key.to_s}; end"
    end
  end
end
