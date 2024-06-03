# frozen_string_literal: true

module AlmaStubbing
  def stub_alma_holding(mms_id:, holding_id:)
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mms_id}/holdings/#{holding_id}")
      .to_return(
        status: 200,
        body: File.read(Rails.root.join("spec", "fixtures", "alma", "holdings", "#{holding_id}.json")),
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_holding_update(mms_id:, holding_id:)
    stub_request(:put, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mms_id}/holdings/#{holding_id}")
      .to_return(
        status: 200,
        body: "{}",
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_alma_barcode(barcode:, status: 200)
    if status == 404
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/items?item_barcode=#{barcode}")
        .to_return(
          status: 200,
          body: {
            "errorsExist" => true,
            "errorList" => {
              "error" =>
                [{ "errorCode" => "401689",
                   "errorMessage" => "No items found for barcode 32101113344913.",
                   "trackingId" => "E01-1908223143-I7FFO-AWAE1965551414" }]
            },
            "result" => nil
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    elsif status == 504
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/items?item_barcode=#{barcode}")
        .to_raise(Net::OpenTimeout.new)
    else
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/items?item_barcode=#{barcode}")
        .to_return(
          status: 200,
          body: File.read(Rails.root.join("spec", "fixtures", "alma", "items", "#{barcode}.json")),
          headers: { "Content-Type" => "application/json" }
        )
    end
  end
end

RSpec.configure do |config|
  config.include AlmaStubbing
end
