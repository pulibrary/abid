# frozen_string_literal: true
class BatchesController < ApplicationController
  def index
    @batch = Batch.new
  end
end
