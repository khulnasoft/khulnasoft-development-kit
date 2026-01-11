# frozen_string_literal: true

require 'terminal-table'

module KDK
  module Command
    # Run IRB console with KDK environment loaded
    class Component < BaseCommand
      def run(args = [])
        @components = KDK.load_components!

        case args.shift
        when 'list'
          list!
        when 'generate-pipeline'
          generate_pipeline!
        when 'verify'
          unless %w[1 yes true].include?(ENV['CI'])
            out.error('You are not in a CI pipeline.')
            return false
          end

          component_name = args.shift&.downcase
          unless components.key?(component_name)
            out.error("Component '#{component_name}' does not exist")
            return false
          end

          components[component_name].smoke_test!

          true
        else
          raise UserInteractionRequired, 'Usage: kdk component <list|generate-pipeline|verify>'
        end
      end

      private

      attr_reader :components

      def generate_pipeline!
        yamls = components.values.map do |component|
          Complib::PipelineSchemaGenerator.new(component).to_yaml
        end

        out.puts Complib::PipelineSchemaGenerator::BASE
        out.puts
        out.puts yamls.join("\n")

        true
      end

      def list!
        rows = components.values.map do |component|
          name = out.wrap_in_color(component.name, out::COLOR_CODE_YELLOW)
          [name, component.feature_category, component.templates.map(&:name).join("\n")]
        end

        table = Terminal::Table.new(
          headings: ['Name', 'Feature category', 'Templates'],
          rows: rows,
          style: { padding_right: 2 }
        )

        out.puts table

        true
      end
    end
  end
end
