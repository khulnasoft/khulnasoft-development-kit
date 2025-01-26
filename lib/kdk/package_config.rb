# frozen_string_literal: true

module KDK
  module PackageConfig
    PROJECTS = {
      gitaly: {
        package_name: 'gitaly',
        package_version: 'main',
        project_path: 'gitaly',
        upload_path: 'build',
        download_path: '_build/bin',
        platform_specific: true
      },
      khulnasoft_shell: {
        package_name: 'khulnasoft-shell',
        package_version: 'main',
        project_path: 'khulnasoft-shell',
        upload_path: 'build',
        download_path: 'bin',
        platform_specific: true
      },
      workhorse: {
        package_name: 'workhorse',
        package_version: 'main',
        project_path: 'khulnasoft/workhorse',
        upload_path: 'build',
        download_path: '.',
        platform_specific: true
      },
      graphql_schema: {
        package_name: 'graphql-schema',
        package_version: 'master',
        project_path: 'khulnasoft',
        upload_path: 'tmp/tests/graphql', # uploaded in khulnasoft-org/khulnasoft
        download_path: 'tmp/tests/graphql',
        platform_specific: false
      }
    }.freeze

    def self.project(name)
      data = PROJECTS[name]
      project_path = KDK.config.kdk_root.join(data[:project_path])

      data.merge(
        package_path: "#{data[:package_name]}.tar.gz",
        project_path: project_path,
        upload_path: project_path.join(data[:upload_path]),
        download_path: project_path.join(data[:download_path])
      )
    end
  end
end
