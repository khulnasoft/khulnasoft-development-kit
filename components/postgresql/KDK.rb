# frozen_string_literal: true

KDK.component do
  feature_category :database

  smoke_test 'Check connection with psql' do
    KDK::Shellout.new('kdk start postgresql').execute

    retry_until_true do
      KDK::Shellout.new("echo '\\conninfo' | kdk psql").execute.success?
    end
  end
end
