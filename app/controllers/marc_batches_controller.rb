# frozen_string_literal: true
class MarcBatchesController < ApplicationController
  before_action :build_sizes, only: [:new, :create]
  before_action :require_authorization

  def show
    @batch = MarcBatch.find(params[:id])

    respond_to do |format|
      format.csv { send_data @batch.to_csv, filename: "batch-#{@batch.id}.csv" }
    end
  end

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
  rescue Net::OpenTimeout
  end

  def destroy
    @batch = MarcBatch.find(params[:id])
    if @batch.synchronized?
      flash.alert = "Unable to delete synchronized Batches."
    else
      @batch.destroy
      flash.notice = "Deleted Batch #{@batch.id}"
    end
    redirect_to batches_path
  end

  def synchronize
    @batch = MarcBatch.find(params[:id])
    @batch.synchronize
    flash.notice = "Synchronized MARC Batch #{@batch.id}"
    redirect_to batches_path
  end

  def build_sizes
    @sizes = ContainerProfile.select_labels("firestone")
  end

  def batch_params
    params.require(:marc_batch).permit(:prefix, absolute_identifiers_attributes: [:barcode, :prefix, :pool_identifier])
  end
end
