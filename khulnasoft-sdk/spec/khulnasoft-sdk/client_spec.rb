# frozen_string_literal: true

RSpec.describe KhulnasoftSDK::Client do
  let(:app_id) { 'app_id' }
  let(:scheme) { 'https' }
  let(:domain) { 'snowplowcollector.com' }
  let(:endpoint) { "#{domain}:443" }
  let(:host) { "#{scheme}://#{domain}" }
  let(:event_name) { 'event_name' }
  let(:event_payload) { { pay: 'load' } }
  let(:method) { 'get' }
  let(:buffer_size) { 1 }
  let(:async) { true }

  let(:emitter) { instance_double(SnowplowTracker::Emitter) }
  let(:tracker) { instance_double(SnowplowTracker::Tracker) }
  let(:self_desc_json) { instance_double(SnowplowTracker::SelfDescribingJson) }

  before do
    allow(SnowplowTracker::Emitter).to receive(:new).and_return(emitter)
    allow(SnowplowTracker::Tracker).to receive(:new).and_return(tracker)
    allow(SnowplowTracker::SelfDescribingJson).to receive(:new).and_return(self_desc_json)
  end

  subject(:client) { described_class.new(app_id: app_id, host: host) }

  shared_examples "uses snowplow's API correctly", :aggregate_failures do
    it 'calls the expected methods with the expected arguments' do
      expect(SnowplowTracker::AsyncEmitter).to receive(:new).with(
        endpoint: endpoint,
        options: { protocol: scheme, method: method, buffer_size: buffer_size }
      ).and_return(emitter)
      expect(SnowplowTracker::Tracker).to receive(:new).with(
        emitters: emitter,
        app_id: app_id,
        namespace: described_class::DEFAULT_TRACKER_NAMESPACE
      ).and_return(tracker)
      expect(SnowplowTracker::SelfDescribingJson).to receive(:new).with(
        described_class::SCHEMAS[:custom_event],
        name: event_name,
        props: event_payload
      ).and_return(self_desc_json)

      expect(tracker).to receive(:set_subject) do |subject|
        expect(subject.details).to eq(
          "p" => "srv",
          "ua" => described_class::USERAGENT
        )
      end
      expect(tracker).to receive(:track_self_describing_event).with(event_json: self_desc_json)

      client.track(event_name, event_payload)
    end
  end

  it_behaves_like "uses snowplow's API correctly"

  context 'with a non-standard port' do
    let(:scheme) { 'http' }
    let(:domain) { 'localhost:9091' }
    let(:endpoint) { domain }

    it_behaves_like "uses snowplow's API correctly"
  end

  context "with an identified user" do
    let(:user_id) { 123 }

    after do
      client.identify(nil)
    end

    context "without user_attributes" do
      it "uses snowplow's API correctly", :aggregate_failures do
        expect(tracker).to receive(:set_subject) { |subject| expect(subject.details).to include("uid" => user_id) }

        expect(tracker).to receive(:track_self_describing_event).with(event_json: self_desc_json)

        client.identify(user_id)

        client.track(event_name, event_payload)
      end
    end

    context "with user_attributes" do
      let(:user_attributes) { { user_name: "Matthew" } }
      let(:user_context) { instance_double(SnowplowTracker::SelfDescribingJson) }

      it "uses snowplow's API correctly", :aggregate_failures do
        expect(tracker).to receive(:set_subject) { |subject| expect(subject.details).to include("uid" => user_id) }

        expect(SnowplowTracker::SelfDescribingJson).to receive(:new).with(
          described_class::SCHEMAS[:user_context],
          user_attributes
        ).and_return(user_context)

        expect(tracker).to receive(:track_self_describing_event).with(
          event_json: self_desc_json,
          context: [user_context]
        )

        client.identify(user_id, user_attributes)

        client.track(event_name, event_payload)
      end
    end
  end

  context "when event_payload is not provided in track method" do
    it "tracks the event with an empty payload", :aggregate_failures do
      expected_payload = {}

      allow(tracker).to receive(:set_subject)

      expect(SnowplowTracker::SelfDescribingJson).to receive(:new).with(
        described_class::SCHEMAS[:custom_event],
        name: event_name,
        props: expected_payload
      ).and_return(self_desc_json)

      expect(tracker).to receive(:track_self_describing_event).with(event_json: self_desc_json)

      client.track(event_name)
    end
  end

  context "when identifying a user without providing user_attributes" do
    let(:user_id) { 123 }

    it "identifies the user with empty attributes", :aggregate_failures do
      expect(KhulnasoftSDK::CurrentUser).to receive(:user_id=).with(user_id)
      expect(KhulnasoftSDK::CurrentUser).to receive(:user_attributes=).with({})

      client.identify(user_id)
    end
  end

  describe 'optional arguments' do
    describe 'buffer_size' do
      subject(:client) { described_class.new(app_id: app_id, host: host, buffer_size: buffer_size) }

      context 'with buffer_size larger than 1' do
        let(:method) { 'post' }
        let(:buffer_size) { 5 }

        it_behaves_like "uses snowplow's API correctly"
      end

      context 'with buffer_size smaller than 1' do
        let(:buffer_size) { 0 }

        it 'raises an ArgumentError' do
          expect { client }.to raise_error(ArgumentError, /buffer_size has to be positive/)
        end
      end
    end

    context 'with async set to false' do
      let(:async) { false }

      subject(:client) { described_class.new(app_id: app_id, host: host, async: async) }

      it 'uses Emitter instead of AsyncEmitter', :aggregate_failures do
        expect(SnowplowTracker::Emitter).to receive(:new).with(
          endpoint: endpoint,
          options: { protocol: scheme, method: method, buffer_size: buffer_size }
        )
        expect(SnowplowTracker::AsyncEmitter).not_to receive(:new)

        client
      end
    end
  end

  describe '#flush_events' do
    it 'sends all events synchronously by default' do
      expect(tracker).to receive(:flush).with(async: false)

      client.flush_events
    end

    context 'when async is set to true' do
      it 'sends all events asynchronously' do
        expect(tracker).to receive(:flush).with(async: true)

        client.flush_events(async: true)
      end
    end
  end
end
