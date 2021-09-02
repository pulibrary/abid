# frozen_string_literal: true
class ContainerProfile
  attr_reader :name, :uri, :source
  def self.sizes
    sizes = {
      "firestone" => {
        "Object" => "C",
        "BoxQ" => "L",
        "Double Elephant size box" => "Z",
        "Double Elephant volume" => "D",
        "Elephant size box" => "P",
        "Elephant volume" => "E",
        "Folio" => "F",
        "Standard records center" => "B",
        "Standard manuscript" => "B",
        "Standard half-manuscript" => "B",
        "Standard other" => "B",
        "Ordinary" => "N",
        "Quarto" => "Q",
        "Small" => "S",
        "Firestone Flat File Large Slim" => "FF",
        "Firestone Flat File Medium" => "FF",
        "Firestone Flat File XL" => "FF",
        "Firestone Flat File XL Slim" => "FF"
      },
      "mudd" => {
        "Mudd OS depth" => "DO",
        "Mudd OS height" => "H",
        "Mudd OS length" => "LO",
        "Mudd OS length, depth" => "LD",
        "Mudd OS height-extra" => "XH",
        "Standard records center" => "S",
        "Standard manuscript" => "S",
        "Standard half-manuscript" => "S",
        "Standard other" => "S",
        "Mudd OS open" => "O",
        "Mudd OS folder" => "C",
        "Mudd OS height, depth-extra" => "XHD"
      }
    }
    sizes["global"] = sizes["firestone"]
    sizes
  end

  def self.select_labels(key)
    sizes[key].map do |label, value|
      ["#{label} (#{value})", value]
    end
  end

  def initialize(container_profile_hash)
    @name = container_profile_hash["name"]
    @uri = container_profile_hash["uri"]
    @source = container_profile_hash
  end

  def abid_prefix(pool_identifier:)
    sizes.dig(pool_identifier, name) || "UNKNOWN"
  end

  # @return [Boolean] whether or not the container profile name is set up in
  #   code to work.
  def configured?
    configured_names.include?(name)
  end

  private

  def configured_names
    @configured_names ||= sizes.values.flat_map(&:keys)
  end

  def sizes
    self.class.sizes
  end
end
