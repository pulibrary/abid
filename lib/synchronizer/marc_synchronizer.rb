# frozen_string_literal: true

require "stringio"
require "httparty"
require "alma"
require "marc"
# This file reopens `class Synchronizer` to nest MarcSynchronizer inside it, so
# the base class has to be defined first.
require "synchronizer"

class Synchronizer
  # Synchronizes an AbID to Alma.
  # Finds an AbID's associated holding record and updates its 852h (call number)
  # with the AbID.
  class MarcSynchronizer
    attr_reader :absolute_identifier

    # Was `delegate :alma_item, to: :absolute_identifier`.
    def alma_item
      absolute_identifier.alma_item
    end

    def initialize(absolute_identifier:)
      @absolute_identifier = absolute_identifier
    end

    def sync!
      update_holding_marc
      url = "#{bibs_base_path}/#{mms_id}/holdings/#{holding_id}"
      data = "<holding><record>#{holding_marc.to_xml}</record></holding>"
      delete_conflicting_abids
      HTTParty.put(url, headers: headers, body: data)
      absolute_identifier.sync_status = "synchronized"
      absolute_identifier.save
    end

    private

    # If we're ignoring size validation then there might be two AbIDs with the
    # same holding, since one changed. Delete the other one.
    def delete_conflicting_abids
      # Was `absolute_identifier.batch.try(:ignore_size_validation)`.
      batch = absolute_identifier.batch
      return unless batch.respond_to?(:ignore_size_validation) && batch.ignore_size_validation
      absolute_identifier.different_size_holding_abids.each(&:destroy)
    end

    def holding
      @holding ||= Alma::BibHolding.find(mms_id: mms_id, holding_id: holding_id)
    end

    def holding_marc
      @holding_marc ||= MARC::XMLReader.new(StringIO.new(holding["anies"][0])).to_a.first
    end

    def update_holding_marc
      # There will always be an 852.
      @modified_holding_marc ||=
        holding_marc.each_by_tag("852") do |field|
          # Means "local"
          field.indicator1 = "8"
          field.subfields.each do |subfield|
            if subfield.code == "h"
              subfield.value = absolute_identifier.full_identifier
            elsif subfield.code == "i"
              # Delete subfield i - unneeded.
              field.subfields.delete(subfield)
            end
          end
          # Add subfield h if one doesn't exist.
          # Was `field["h"].blank?`; same /\A[[:space:]]*\z/ test ActiveSupport used.
          if field["h"].nil? || /\A[[:space:]]*\z/.match?(field["h"].to_s)
            field.append(MARC::Subfield.new("h", absolute_identifier.full_identifier))
          end
        end
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
end
