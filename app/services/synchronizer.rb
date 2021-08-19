# frozen_string_literal: true
class Synchronizer
  def self.for(absolute_identifier:)
    if absolute_identifier.batch.is_a?(MarcBatch)
      MarcSynchronizer.new(absolute_identifier: absolute_identifier)
    else
      new(absolute_identifier: absolute_identifier)
    end
  end
  class MarcSynchronizer
    attr_reader :absolute_identifier
    delegate :alma_item, to: :absolute_identifier
    def initialize(absolute_identifier:)
      @absolute_identifier = absolute_identifier
    end

    def holding
      @holding ||= Alma::BibHolding.find(mms_id: mms_id, holding_id: holding_id)
    end

    def holding_marc
      @holding_marc ||= MARC::XMLReader.new(StringIO.new(holding["anies"][0])).to_a.first
    end

    def update_holding_marc
      @modified_holding_marc ||=
        begin
          holding_marc.each_by_tag("852") do |field|
            field.indicator1 = "8"
            field.subfields.each do |subfield|
              if subfield.code == "h"
                subfield.value = absolute_identifier.full_identifier
              end
            end
            if field["h"].blank?
              field.append(MARC::Subfield.new("h", absolute_identifier.full_identifier))
            end
          end
        end
    end

    def sync!
      update_holding_marc
      url = "#{bibs_base_path}/#{mms_id}/holdings/#{holding_id}"
      data = "<holding><record>#{holding_marc.to_xml}</record></holding>"
      HTTParty.put(url, headers: headers, body: data)
      absolute_identifier.sync_status = "synchronized"
      absolute_identifier.save
    end

    def headers
      alma_item.class.headers.merge(
        "Content-Type": "application/xml"
      )
    end

    def bibs_base_path
      alma_item.class.bibs_base_path
    end

    def mms_id
      alma_item["bib_data"]["mms_id"]
    end

    def holding_id
      alma_item["holding_data"]["holding_id"]
    end
  end
  attr_reader :absolute_identifier
  def initialize(absolute_identifier:)
    @absolute_identifier = absolute_identifier
  end

  def sync!
    absolute_identifier.sync_status = "synchronizing"
    absolute_identifier.save
    if absolute_identifier.generate_abid
      top_container.indicator = absolute_identifier.full_identifier
    end
    top_container.location = absolute_identifier.batch.location_uri
    top_container.container_profile = absolute_identifier.batch.container_profile_uri
    top_container.barcode = absolute_identifier.barcode
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
