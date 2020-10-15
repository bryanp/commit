# frozen_string_literal: true

require "fileutils"
require "yaml"

require_relative "../../operation"

require_relative "../git/commit"
require_relative "../git/pull"
require_relative "../git/push"

module Commit
  module Operations
    module Changelogs
      class Update < Operation
        def call
          return unless applicable?

          Git::Pull.call(scope: scope, event: event)

          generate_release_data

          Git::Commit.call(scope: scope, event: event, message: "update releases")
          Git::Push.call(scope: scope, event: event)
        end

        private def generate_release_data
          entry = {
            "id" => id,
            "type" => type,
            "summary" => summary,
            "link" => link,
            "author" => {
              "username" => author_username,
              "link" => author_link
            }
          }

          ensure_releases_data

          existing_release = releases_data.find { |release|
            release["version"] == release_name
          }

          unless existing_release
            existing_release = {
              "version" => release_name,
              "changes" => []
            }

            releases_data << existing_release
          end

          existing_release["changes"].unshift(entry)

          releases_data_path.open("w+") do |file|
            file.write(releases_data.sort { |a, b| b["version"] <=> a["version"] }.to_yaml)
          end
        end

        private def applicable?
          merged? && default_branch? && release? && changelog? && changetype?
        end

        private def merged?
          event.config.pull_request.merged!
        end

        private def default_branch?
          event.config.pull_request.base.ref! == event.config.pull_request.base.repo.default_branch!
        end

        private def release?
          !release_name.nil?
        end

        private def changelog?
          (configured_changelog_labels & event.config.pull_request.labels.map(&:name!)).any?
        end

        private def changetype?
          !type.nil?
        end

        private def configured_changelog_labels
          config.commit.changelogs.map(&:label!)
        end

        private def configured_changetypes
          config.commit.changetypes
        end

        private def release_name
          @_release_name ||= event.config.pull_request.milestone.title!
        end

        private def id
          @_id ||= event.config.pull_request.number!
        end

        private def type
          event_labels = event.config.pull_request.labels.map(&:name!)

          changetype = configured_changetypes.find { |configured_changetype|
            event_labels.include?(configured_changetype.label!)
          }

          return nil if changetype&.settings.nil?

          @_type ||= (changetype.name! || changetype.label!)
        end

        private def summary
          @_summary ||= event.config.pull_request.title!
        end

        private def link
          @_link ||= event.config.pull_request.html_url!
        end

        private def author_username
          @_author_username ||= event.config.pull_request.user.login!
        end

        private def author_link
          @_author_link ||= event.config.pull_request.user.html_url!
        end

        private def ensure_releases_data
          return if releases_data_path.exist?
          FileUtils.mkdir_p(releases_data_path.dirname)
          FileUtils.touch(releases_data_path)
        end

        private def releases_data
          @_releases_data ||= (YAML.safe_load(releases_data_path.read) || [])
        end

        private def releases_data_path
          @_releases_data_path ||= scope.path.join("data/releases.yml")
        end
      end
    end
  end
end
