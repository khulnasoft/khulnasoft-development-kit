# frozen_string_literal: true

module Rubocop
  module Cop
    module CodeReuse
      # Cop that denies the use of ActiveRecord methods outside of models.
      #
      # @example
      #   # bad
      #   # In app/workers/some_worker.rb
      #   User.where(admin: true)
      #
      #   # good
      #   # In app/workers/some_worker.rb
      #   User.admins
      #   # In app/models/user.rb
      #   scope :admins, -> { where(admin: true) }
      #
      # See also:
      # - https://docs.khulnasoft.com/ee/development/reusing_abstractions.html
      # - https://khulnasoft.com/khulnasoft-org/khulnasoft-foss/issues/49653
      class ActiveRecord < RuboCop::Cop::Base
        MSG = 'This method can only be used inside an ActiveRecord model: ' \
          'https://docs.khulnasoft.com/ee/development/reusing_abstractions.html'

        # Various methods from ActiveRecord::Querying that are denied. We
        # exclude some generic ones such as `any?` and `first`, as these may
        # lead to too many false positives, since `Array` also supports these
        # methods.
        #
        # The keys of this Hash are the denied method names. The values are
        # booleans that indicate if the method should only be denied if any
        # arguments are provided.
        NOT_ALLOWED = {
          average: true,
          calculate: true,
          count_by_sql: true,
          create_with: true,
          distinct: false,
          eager_load: true,
          exists?: true,
          find_by: true,
          find_by!: true,
          find_by_sql: true,
          find_each: true,
          find_in_batches: true,
          find_or_create_by: true,
          find_or_create_by!: true,
          find_or_initialize_by: true,
          first!: false,
          first_or_create: true,
          first_or_create!: true,
          first_or_initialize: true,
          from: true,
          group: true,
          having: true,
          ids: false,
          includes: true,
          joins: true,
          lock: false,
          many?: false,
          offset: true,
          order: true,
          pluck: true,
          preload: true,
          readonly: false,
          references: true,
          reorder: true,
          rewhere: true,
          take: false,
          take!: false,
          unscope: false,
          where: false,
          with: true
        }.freeze

        def on_send(node)
          receiver = node.children[0]
          send_name = node.children[1]
          first_arg = node.children[2]

          return unless receiver && NOT_ALLOWED.key?(send_name)

          # If the rule requires an argument to be given, but none are
          # provided, we won't register an offense. This prevents us from
          # adding offenses for `project.group`, while still covering
          # `Project.group(:name)`.
          return if NOT_ALLOWED[send_name] && !first_arg

          add_offense(node.loc.selector)
        end
      end
    end
  end
end
