# frozen_string_literal: true

require "json"

module Abid
  module Actions
    module Health
      # Replaces the mounted HealthMonitor::Engine (health-monitor-rails).
      #
      # This endpoint is a deployment contract: config/deploy/production.hcl and
      # staging.hcl both poll /health.json every 10s and restart the allocation
      # on failure, so the path and the status codes must not change.
      #
      # health-monitor-rails rescued any provider exception and responded 503;
      # spec/requests/health_check_spec.rb depends on that (it stubs the
      # database call to raise, then expects :service_unavailable). The rescue
      # below is therefore load-bearing, not defensive padding.
      class Show < Abid::Action
        # Matches the file_absence provider the Rails app configured: the
        # load balancer drains a node by creating this file.
        DRAIN_FILE = "public/remove-from-nginx"

        def handle(_request, response)
          statuses = [database_status, file_absence_status]
          failed = statuses.any? { |status| status[:status] != "OK" }

          response.format = :json
          response.status = failed ? 503 : 200
          response.body = {
            results: statuses,
            status: failed ? "ERROR" : "OK"
          }.to_json
        end

        private

        def database_status
          Hanami.app["db.gateway"].connection.run("SELECT 1")
          { name: "Database", status: "OK", message: nil }
        rescue StandardError => e
          { name: "Database", status: "ERROR", message: e.message }
        end

        def file_absence_status
          path = Abid::APP_ROOT.join(DRAIN_FILE)
          return { name: "FileAbsence", status: "OK", message: nil } unless path.exist?

          { name: "FileAbsence", status: "ERROR", message: "#{DRAIN_FILE} is present" }
        rescue StandardError => e
          { name: "FileAbsence", status: "ERROR", message: e.message }
        end
      end
    end
  end
end
