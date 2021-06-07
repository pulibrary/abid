# frozen_string_literal: true
class Synchronizer
  attr_reader :absolute_identifier
  def initialize(absolute_identifier:)
    @absolute_identifier = absolute_identifier
  end

  def sync!
    absolute_identifier.sync_status = "synchronizing"
    absolute_identifier.save
    top_container.indicator = absolute_identifier.full_identifier
    top_container.location = absolute_identifier.batch.location_uri
    top_container.container_profile = absolute_identifier.batch.container_profile_uri
    aspace_client.save_top_container(top_container: top_container)
    absolute_identifier.sync_status = "synchronized"
    absolute_identifier.save
  end

  def top_container
    @top_container ||= aspace_client.get_top_container(ref: absolute_identifier.top_container_uri)
  end

  def aspace_client
    @aspace_client ||= Aspace::Client.new
  end
end
