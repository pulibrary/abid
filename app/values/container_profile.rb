# frozen_string_literal: true
class ContainerProfile
  attr_reader :name, :uri
  def initialize(container_profile_hash)
    @name = container_profile_hash["name"]
    @uri = container_profile_hash["uri"]
  end

  def abid_prefix(pool_identifier:)
    sizes.dig(pool_identifier, name) || "UNKNOWN"
  end

  private

  def sizes
    sizes = {
      "firestone" => {
        "Objects" => "C",
        "BoxQ" => "L",
        "Double Elephant size box" => "Z",
        "Double Elephant volume" => "D",
        "Elephant size box" => "P",
        "Elephant volume" => "E",
        "Folio" => "F",
        "NBox" => "B",
        "Standard records center" => "B",
        "Standard manuscript" => "B",
        "Standard half-manuscript" => "B",
        "Standard other" => "B",
        "Ordinary" => "N",
        "Quarto" => "Q",
        "Small" => "S"
      },
      "mudd" => {
        "Mudd OS depth" => "DO",
        "Mudd OS height" => "H",
        "Mudd OS length" => "LO",
        "Mudd OS Extra height" => "XH",
        "Mudd OS Extra height, depth" => "XHD",
        "Standard records center" => "S",
        "Standard manuscript" => "S",
        "Standard half-manuscript" => "S",
        "Standard other" => "S",
        "Mudd OS open" => "O",
        "Mudd Oversize folder" => "C"
      }
    }
    sizes["global"] = sizes["firestone"]
    sizes
  end
end
