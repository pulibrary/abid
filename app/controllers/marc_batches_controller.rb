# frozen_string_literal: true
class MarcBatchesController < ApplicationController
  def new
    @batch = MarcBatch.new
    @batch.absolute_identifiers.build(pool_identifier: "firestone")
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

  def batch_params
    params.require(:marc_batch).permit(absolute_identifiers_attributes: [:barcode, :prefix, :pool_identifier])
  end
end
