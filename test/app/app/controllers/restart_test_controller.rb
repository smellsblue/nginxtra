class RestartTestController < ApplicationController
  def index
  end

  def long_request
    stamp = Time.now.to_i
    sleep_time = params[:sleep].to_f if params[:sleep]
    sleep_time ||= 10.0
    sleep_time = 1.0 if sleep_time < 1.0
    sleep_time = 10.0 if sleep_time > 10.0
    logger.info "Sleeping for #{sleep_time}s from stamp #{stamp}"
    sleep sleep_time
    logger.info "Done sleeping for #{sleep_time}s from stamp #{stamp}"
    render text: "Done"
  end

  def restart_nginxtra
  end
end
