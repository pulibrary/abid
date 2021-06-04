# frozen_string_literal: true
class BatchesController < ApplicationController
  def index
    @batch = Batch.new
    @container_profiles = client.container_profiles
    @locations = client.locations
  end

  def client
    @client ||= Aspace::Client.new
  end
end
