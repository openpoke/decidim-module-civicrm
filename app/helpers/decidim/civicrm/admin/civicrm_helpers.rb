# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      module CivicrmHelpers
        def last_sync_class(object)
          return "" unless object.last_sync

          return "text-alert" if object.needs_sync?
          return "text-warning" if object.last_sync < 1.week.ago

          "text-success"
        end

        def sync_status(group)
          if group.last_sync.nil?
            "<span class='label text-warning'>#{t("decidim.civicrm.admin.not_synced")}</span>"
          elsif group.needs_sync?
            "<span class='label #{last_sync_class(group)}'>#{t("decidim.civicrm.admin.needs_sync")}</span>"
          else
            "<span class='label text-success'>#{t("decidim.civicrm.admin.synced")}</span>"
          end.html_safe
        end

        def check_icon(valid, label: false, icon: true)
          if valid
            pic = icon "check-line", class: "action-icon text-success"
            txt = "<span class='label text-success'>#{label.is_a?(String) ? label : t("decidim.civicrm.admin.enabled")}</span>"
          else
            pic = icon "close-line", class: "action-icon text-muted"
            txt = "<span class='label text-alert'>#{label.is_a?(String) ? label : t("decidim.civicrm.admin.disabled")}</span>"
          end

          txt = if label
                  icon ? "#{pic} #{txt}" : txt
                else
                  pic
                end
          txt.html_safe
        end

        def civicrm_job_queue_stats # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
          return nil unless defined?(Sidekiq)

          job_stats = Hash.new { |h, k| h[k] = { enqueued: 0, processing: 0, failed: 0, last_started_at: nil, enqueued_at: nil } }

          # Count enqueued CiviCRM jobs and track when they were added
          Sidekiq::Queue.all.each do |queue|
            queue.each do |job|
              next unless job.display_class.start_with?("Decidim::Civicrm::")

              job_stats[job.display_class][:enqueued] += 1
              # Track the oldest enqueued time (first job added)
              enqueued_time = Time.zone.at(job.item["enqueued_at"] || job.item["created_at"])
              if job_stats[job.display_class][:enqueued_at].nil? || enqueued_time < job_stats[job.display_class][:enqueued_at]
                job_stats[job.display_class][:enqueued_at] = enqueued_time
              end
            end
          end

          # Count processing CiviCRM jobs and track when they started
          Sidekiq::Workers.new.each do |_process_id, _thread_id, work|
            job_class = work.job.display_class
            next unless job_class.start_with?("Decidim::Civicrm::")

            job_stats[job_class][:processing] += 1
            # Track the latest start time
            run_at = Time.zone.at(work["run_at"])
            job_stats[job_class][:last_started_at] = run_at if job_stats[job_class][:last_started_at].nil? || run_at > job_stats[job_class][:last_started_at]
          end

          # Count failed CiviCRM jobs
          Sidekiq::RetrySet.new.each do |job|
            job_stats[job.display_class][:failed] += 1 if job.display_class.start_with?("Decidim::Civicrm::")
          end

          # Sort by job class name for consistent display
          job_stats.sort_by { |job_class, _| job_class }
        end
      end
    end
  end
end
