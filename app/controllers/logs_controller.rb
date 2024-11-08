class LogsController < ApplicationController
  # before_action :authorize

  def changelog
    @logs = ChangeLog.parse_from_file(Rails.root.join("changelog.yaml"))
  end
end
