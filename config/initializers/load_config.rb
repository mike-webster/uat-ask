CONFIG_PATH = Rails.root.join("config", "config.yml").freeze

APP_CONFIG = YAML.load(ERB.new(File.read(CONFIG_PATH)).result)
