# frozen_string_literal: true
module Abid
  def config
    @config ||= all_environment_config[Rails.env]
  end

  def all_environment_config
    @all_environment_config ||= YAML.safe_load(yaml, aliases: true).with_indifferent_access
  end

  private

  def yaml
    ERB.new(File.read(Rails.root.join("config", "config.yml"))).result
  end

  module_function :config, :yaml, :all_environment_config
end
