# frozen_string_literal: true

module KDK
  module Complib
    module KdkModule
      def components
        @components ||= load_components!
      end

      def load_components!
        start = Time.now
        all_component_paths.to_h do |name, path|
          @component_name = name
          load(path)
          [name, @component]
        ensure
          @component_name = nil
          @component = nil
        end
      ensure
        KDK::Output.debug("Loaded #{all_component_paths.size} components in #{Utils.format_duration(Time.now - start)}.")
      end

      def all_component_paths
        Dir[root.join('components/*/KDK.rb')].to_h do |path|
          name = Pathname(path).relative_path_from(root).to_s.split('/')[1]
          [name, path]
        end
      end

      def component(&blk)
        raise "Not in a component definition." unless @component_name

        dsl = ComponentDsl.new(@component_name)
        dsl.instance_eval(&blk)
        @component = dsl.component
      end
    end
  end
end
