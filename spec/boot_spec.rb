# frozen_string_literal: true

require "hanami_helper"

# The spec suite requires every domain file explicitly through
# spec/rails_helper.rb, which masked the fact that a plain `hanami server`
# boot did not load them at all: the first request raised
# `uninitialized constant User`. This boots the app in a clean subprocess,
# exactly as the server does, so the requires cannot be masked again.
RSpec.describe "Application boot" do
  it "resolves the domain constants without the spec helper's requires" do
    constants = %w[ApplicationRecord User Batch MarcBatch AbsoluteIdentifier
                   BarcodeService ContainerProfile Location TopContainer
                   Synchronizer HoneybadgerCheck]

    script = <<~RUBY
      require "hanami/boot"
      missing = %w[#{constants.join(' ')}].reject { |c| Object.const_defined?(c) }
      print(missing.empty? ? "OK" : "MISSING: " + missing.join(", "))
    RUBY

    output = `cd #{Shellwords.escape(Abid::APP_ROOT.to_s)} && bundle exec ruby -e #{Shellwords.escape(script)} 2>/dev/null`

    expect(output).to end_with("OK")
  end
end
