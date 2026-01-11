# frozen_string_literal: true

namespace :object_store do
  desc 'Setup Object Store default buckets'
  task :setup do
    next unless KDK.config.object_store.enabled?

    data_dir = KDK::Services::Minio.new.data_dir
    KDK.config.object_store.objects.each do |key, data|
      bucket = data['bucket']
      raise KDK::UserInteractionRequired, "Expected a `bucket` name for object_store.objects.#{key} in kdk.yml." if bucket.nil? || bucket.empty?

      bucket_directory = data_dir.join(bucket)

      bucket_directory.mkpath unless bucket_directory.exist?
    end
  end
end
