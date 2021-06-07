# frozen_string_literal: true
class BatchesController < ApplicationController
  def index
    @batch = Batch.new
    @container_profiles = client.container_profiles
    @locations = client.locations
  end

  def create
    @batch = Batch.new(batch_params)
    @batch.user = current_user
    if @batch.save
      redirect_to root_path
    else
      @container_profiles = client.container_profiles
      @locations = client.locations
      render :index
    end
  end

  def synchronize
    @batch = Batch.find(params[:id])
    @batch.synchronize
    flash.notice = "Synchronized Batch #{@batch.id}"
    redirect_to root_path
  end

  def client
    @client ||= Aspace::Client.new
  end

  def batch_params
    params.require(:batch).permit(:call_number, :start_box, :end_box, :container_profile_uri, :location_uri, :first_barcode)
  end
end
