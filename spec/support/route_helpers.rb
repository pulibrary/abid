# frozen_string_literal: true

# Rails path helpers used by the spec examples. Defining them here means the
# examples keep their original `redirect_to batches_path` / `visit root_path`
# wording instead of being rewritten to Hanami's routes API.
module RouteHelpers
  def root_path = "/"
  def batches_path = "/batches"
  def batch_path(batch) = "/batches/#{batch.respond_to?(:id) ? batch.id : batch}"
  def synchronize_all_batches_path = "/batches/synchronize_all"
  def synchronize_batch_path(batch) = "/batches/#{batch.respond_to?(:id) ? batch.id : batch}/synchronize"
  def new_marc_batch_path = "/marc_batches/new"
  def marc_batches_path = "/marc_batches"
  def marc_batch_path(batch) = "/marc_batches/#{batch.respond_to?(:id) ? batch.id : batch}"
  def new_user_session_path = "/sign_in"
  def destroy_user_session_path = "/sign_out"
end

RSpec.configure do |config|
  config.include RouteHelpers
end
