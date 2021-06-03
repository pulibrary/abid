# frozen_string_literal: true
class BarcodeService
  def self.valid?(barcode)
    new(barcode).valid?
  end

  attr_reader :barcode

  # @parm barcode [String]
  def initialize(barcode)
    @barcode = barcode
  end

  # Generate a set of next barcode values
  # @param count [Integer] number of barcodes to generate
  # @return [Array<String>]
  def next(count:)
    return [] unless count.positive?
    # Get the next base number in the sequence; including leading zeros
    next_number = format("%013d", (base_number + 1))
    service = self.class.new("#{next_number}#{checksum(next_number.to_i)}")
    service.next(count: count - 1).prepend(service.barcode)
  end

  # Checks if a barcode value is valid
  # @return [Boolean]
  def valid?
    return false unless integer?
    checksum(base_number) == base_checksum
  end

  private

  # Returns the barcode number without it's checksum
  # @return [Integer]
  def base_number
    barcode[0..-2].to_i
  end

  # Returns the checksum of the barcode
  # @return [Integer]
  def base_checksum
    barcode[-1].to_i
  end

  # Calculates a checksum value using the Luhn algorithm
  # @param number [Integer]
  # @return [Integer]
  def checksum(number)
    # Reverse the digits in the number
    digits = number.to_s.reverse.scan(/\d/).map(&:to_i)
    digits = digits.each_with_index.map do |digit, i|
      # Multiply digits with even (zero-based) index values by two
      digit *= 2 if i.even?
      # Subtract 9 if the resulting value is greater than 9
      digit > 9 ? digit - 9 : digit
    end
    # Add the digits and modulo 10 the resulting sum
    mod = digits.sum % 10
    # Return 0 if modulus is 0
    # Otherwise, return 10 minus modulus
    mod.zero? ? 0 : 10 - mod
  end

  # Check if barcode is an integer
  # @return [Boolean]
  def integer?
    Integer(barcode)
  rescue
    false
  end
end
