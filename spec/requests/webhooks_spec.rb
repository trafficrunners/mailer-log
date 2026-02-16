# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MailerLog::WebhooksController, type: :request do
  let(:signing_key) { 'test_signing_key_12345' }
  let(:fixtures_path) { File.join(__dir__, '..', 'fixtures', 'mailgun_webhooks') }

  before do
    allow(MailerLog.configuration).to receive(:webhook_signing_key).and_return(signing_key)
    Rails.cache.clear
  end

  describe 'POST #mailgun' do
    let(:timestamp) { Time.current.to_i.to_s }
    let(:token) { SecureRandom.hex(25) }
    let(:signature) do
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new('SHA256'),
        signing_key,
        "#{timestamp}#{token}"
      )
    end

    let(:signature_params) do
      {
        'signature' => {
          'timestamp' => timestamp,
          'token' => token,
          'signature' => signature
        }
      }
    end

    let(:email) { create(:mailer_log_email, message_id: 'test-message-id@example.mail') }

    let(:webhook_params) do
      signature_params.merge(
        'event-data' => {
          'id' => SecureRandom.hex(16),
          'event' => 'delivered',
          'timestamp' => Time.current.to_f,
          'recipient' => 'user@example.com',
          'message' => {
            'headers' => {
              'message-id' => 'test-message-id@example.mail'
            }
          }
        }
      )
    end

    def do_request(params = webhook_params)
      post '/admin/mailer-log/webhooks/mailgun', params: params
    end

    def fixture_params(name)
      fixture = JSON.parse(File.read(File.join(fixtures_path, "#{name}.json")))
      fixture['event-data']['id'] = SecureRandom.hex(16)
      fixture['event-data']['message']['headers']['message-id'] = email.message_id
      signature_params.merge(fixture)
    end

    context 'with valid signature' do
      it 'returns ok status' do
        email

        do_request

        expect(response).to have_http_status(:ok)
      end

      it 'creates an event for the email' do
        email

        expect { do_request }.to change(MailerLog::Event, :count).by(1)

        event = MailerLog::Event.last
        expect(event.email).to eq(email)
        expect(event.event_type).to eq('delivered')
        expect(event.recipient).to eq('user@example.com')
      end

      it 'updates email status' do
        email

        do_request

        expect(email.reload.status).to eq('delivered')
        expect(email.delivered_at).to be_present
      end

      context 'when email not found' do
        let(:webhook_params) do
          signature_params.merge(
            'event-data' => {
              'id' => SecureRandom.hex(16),
              'event' => 'delivered',
              'timestamp' => Time.current.to_f,
              'recipient' => 'user@example.com',
              'message' => {
                'headers' => {
                  'message-id' => 'nonexistent@example.com'
                }
              }
            }
          )
        end

        it 'returns ok without creating event' do
          expect { do_request }.not_to change(MailerLog::Event, :count)

          expect(response).to have_http_status(:ok)
        end
      end

      context 'with different event types' do
        %w[opened clicked bounced].each do |event_type|
          context "when event is #{event_type}" do
            let(:webhook_params) do
              signature_params.merge(
                'event-data' => {
                  'id' => SecureRandom.hex(16),
                  'event' => event_type,
                  'timestamp' => Time.current.to_f,
                  'recipient' => 'user@example.com',
                  'message' => {
                    'headers' => {
                      'message-id' => 'test-message-id@example.mail'
                    }
                  }
                }
              )
            end

            it "creates #{event_type} event" do
              email

              expect { do_request }.to change(MailerLog::Event, :count).by(1)

              expect(MailerLog::Event.last.event_type).to eq(event_type)
            end
          end
        end
      end

      context 'with permanent_fail event' do
        let(:webhook_params) do
          signature_params.merge(
            'event-data' => {
              'id' => SecureRandom.hex(16),
              'event' => 'permanent_fail',
              'timestamp' => Time.current.to_f,
              'recipient' => 'user@example.com',
              'message' => {
                'headers' => {
                  'message-id' => 'test-message-id@example.mail'
                }
              }
            }
          )
        end

        it 'normalizes to bounced event type' do
          email

          do_request

          expect(MailerLog::Event.last.event_type).to eq('bounced')
          expect(email.reload.status).to eq('bounced')
        end
      end

      context 'with duplicate event' do
        let(:event_id) { 'duplicate-event-id' }
        let(:webhook_params) do
          signature_params.merge(
            'event-data' => {
              'id' => event_id,
              'event' => 'delivered',
              'timestamp' => Time.current.to_f,
              'recipient' => 'user@example.com',
              'message' => {
                'headers' => {
                  'message-id' => 'test-message-id@example.mail'
                }
              }
            }
          )
        end

        it 'deduplicates and returns ok' do
          email

          do_request
          expect(MailerLog::Event.count).to eq(1)

          do_request
          expect(MailerLog::Event.count).to eq(1)

          expect(response).to have_http_status(:ok)
        end
      end

      context 'with tracking_id header' do
        let(:email) { create(:mailer_log_email) }

        let(:webhook_params) do
          signature_params.merge(
            'event-data' => {
              'id' => SecureRandom.hex(16),
              'event' => 'delivered',
              'timestamp' => Time.current.to_f,
              'recipient' => 'user@example.com',
              'message' => {
                'headers' => {
                  'x-mailer-log-tracking-id' => email.tracking_id
                }
              }
            }
          )
        end

        it 'finds email by tracking_id' do
          email

          expect { do_request }.to change(MailerLog::Event, :count).by(1)

          expect(MailerLog::Event.last.email).to eq(email)
        end
      end
    end

    context 'with realistic Mailgun payloads' do
      context 'delivered event with delivery-status and envelope' do
        it 'creates event with delivery status in raw_payload' do
          email

          do_request(fixture_params(:delivered))

          expect(response).to have_http_status(:ok)

          event = MailerLog::Event.last
          expect(event.event_type).to eq('delivered')
          expect(event.recipient).to eq('user@example.com')
          expect(event.raw_payload).to include('delivery_status')
          expect(event.raw_payload['delivery_status']).to include('code' => '250', 'tls' => 'true')
          expect(event.raw_payload).to include('envelope')
          expect(email.reload.status).to eq('delivered')
        end
      end

      context 'opened event with client-info and geolocation' do
        it 'creates event with client info and geolocation' do
          email

          do_request(fixture_params(:opened))

          expect(response).to have_http_status(:ok)

          event = MailerLog::Event.last
          expect(event.event_type).to eq('opened')
          expect(event.device_type).to eq('desktop')
          expect(event.client_name).to eq('GmailImageProxy')
          expect(event.client_os).to eq('Windows')
          expect(event.user_agent).to include('GoogleImageProxy')
          expect(event.country).to eq('US')
          expect(event.region).to eq('CA')
          expect(event.city).to eq('San Francisco')
          expect(event.ip_address).to eq('198.51.100.163')
          expect(email.reload.status).to eq('opened')
        end
      end

      context 'clicked event with URL, client-info and geolocation' do
        it 'creates event with click URL and client details' do
          email

          do_request(fixture_params(:clicked))

          expect(response).to have_http_status(:ok)

          event = MailerLog::Event.last
          expect(event.event_type).to eq('clicked')
          expect(event.url).to include('password/edit')
          expect(event.device_type).to eq('desktop')
          expect(event.client_name).to eq('Chrome')
          expect(event.client_os).to eq('OS X')
          expect(event.country).to eq('DE')
          expect(event.city).to eq('Berlin')
          expect(event.ip_address).to eq('203.0.113.188')
          expect(email.reload.status).to eq('clicked')
        end
      end

      context 'full email lifecycle: delivered → opened → clicked' do
        it 'processes all events and updates status progressively' do
          email

          do_request(fixture_params(:delivered))
          expect(email.reload.status).to eq('delivered')
          expect(email.delivered_at).to be_present

          do_request(fixture_params(:opened))
          expect(email.reload.status).to eq('opened')
          expect(email.opened_at).to be_present

          do_request(fixture_params(:clicked))
          expect(email.reload.status).to eq('clicked')
          expect(email.clicked_at).to be_present

          expect(email.events.count).to eq(3)
          expect(email.events.pluck(:event_type)).to contain_exactly('delivered', 'opened', 'clicked')
        end
      end
    end

    context 'with invalid signature' do
      let(:signature) { 'invalid_signature' }

      it 'returns unauthorized' do
        do_request

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not create event' do
        expect { do_request }.not_to change(MailerLog::Event, :count)
      end
    end

    context 'with missing signature' do
      let(:webhook_params) do
        {
          'event-data' => {
            'id' => SecureRandom.hex(16),
            'event' => 'delivered'
          }
        }
      end

      it 'returns unauthorized' do
        do_request

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'without signing key configured' do
      before do
        allow(MailerLog.configuration).to receive(:webhook_signing_key).and_return(nil)
      end

      it 'returns unauthorized' do
        do_request

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
