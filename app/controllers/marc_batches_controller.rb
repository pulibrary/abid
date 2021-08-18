# frozen_string_literal: true
class MarcBatchesController < ApplicationController
  before_action :build_sizes, only: [:new, :create]

  def new
    @batch = MarcBatch.new
    @batch.absolute_identifiers.build
  end

  def create
    @batch = MarcBatch.new(batch_params)
    @batch.user = current_user
    if @batch.save
      flash.notice = "Created MARC Batch"
      redirect_to batches_path
    else
      render :new
    end
  end

  def build_sizes
    @sizes = ContainerProfile.select_labels("firestone")
  end

  def batch_params
    params.require(:marc_batch).permit(absolute_identifiers_attributes: [:barcode, :prefix, :pool_identifier])
  end
end
