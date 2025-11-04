# Mission Control — Jobs configuration
# Dashboard for monitoring Solid Queue background jobs

# Configure the base controller for authentication
# - Development: No authentication required (convenient for local development)
# - Production: Requires Rails 8 authentication (via authenticated? method)

Rails.application.config.to_prepare do
  MissionControl::Jobs.base_controller_class = "MissionControlAuthenticatedController"
end
