# frozen_string_literal: true

require_relative "lib/edgescan_api"
require_relative "lib/edgescan_asset"
require_relative "lib/edgescan_vulnerability"
require_relative "lib/edgescan_location_specifier"
require_relative "lib/edgescan_definition"
require_relative "lib/kenna_api"

module Kenna
  module Toolkit
    class EdgescanTask < Kenna::Toolkit::BaseTask
      def self.metadata
        {
          id: "edgescan",
          name: "Edgescan",
          description: "Pulls assets and vulnerabilitiies from Edgescan",
          options: [
            { name: "edgescan_token",
              type: "api_key",
              required: true,
              default: nil,
              description: "Edgescan Token" },
            { name: "edgescan_page_size",
              type: "string",
              required: false,
              default: 100,
              description: "Edgescan page size" },
            { name: "edgescan_api_host",
              type: "hostname",
              required: false,
              default: "live.edgescan.com",
              description: "Edgescan API Hostname" },
            { name: "kenna_api_key",
              type: "api_key",
              required: false,
              default: nil,
              description: "Kenna API Key" },
            { name: "kenna_api_host",
              type: "hostname",
              required: false,
              default: "api.us.kennasecurity.com",
              description: "Kenna API Hostname" },
            { name: "kenna_connector_id",
              type: "integer",
              required: true,
              default: nil,
              description: "Kenna connector ID" },
            { name: "output_directory",
              type: "filename",
              required: false,
              default: "output/edgescan",
              description: "The task will write JSON files here (path is relative to #{$basedir})" }
          ]
        }
      end

      def run(opts)
        super # opts -> @options

        edgescan_api = Kenna::Toolkit::Edgescan::EdgescanApi.new(@options)
        kenna_api = Kenna::Toolkit::Edgescan::KennaApi.new(@options)

        edgescan_api.fetch_in_batches do |edgescan_assets, edgescan_definitions|
          edgescan_assets.each do |edgescan_asset|
            kenna_api.add_assets(edgescan_asset)
            kenna_api.add_vulnerabilities(edgescan_asset.vulnerabilities)
          end

          kenna_api.add_definitions(edgescan_definitions)

          kenna_api.upload
        end

        kenna_api.kickoff
      rescue Kenna::Toolkit::Edgescan::EdgescanApi::ApiError
        fail_task "Unable to retrieve assets, please check credentials"
      end
    end
  end
end
