# Background job for applying NPPES incremental updates
# This job processes weekly update files without blocking the application
#
# Usage:
#   NppesUpdateJob.perform_later('/path/to/weekly_update.csv')
#
# The job will:
# 1. Read the CSV file
# 2. Update existing providers or create new ones
# 3. Sync related data (addresses, taxonomies, identifiers)
# 4. Generate a summary report

class NppesUpdateJob < ApplicationJob
  queue_as :default

  # Retry up to 3 times with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(csv_path)
    puts "\n" + "="*70
    puts "NPPES INCREMENTAL UPDATE JOB"
    puts "="*70
    puts "CSV File: #{csv_path}"
    puts "Started: #{Time.current}"
    puts "="*70

    worker = NppesUpdateWorker.new
    worker.perform(csv_path)

    puts "\n" + "="*70
    puts "✓ UPDATE JOB COMPLETE"
    puts "="*70
  end
end
