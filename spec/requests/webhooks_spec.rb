# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MailerLog::WebhooksController, type: :request do
  let(:signing_key) { 'test_signing_key_12345' }

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

    let(:email) { create(:mailer_log_email, message_id: 'test-message-id@mail.example.com') }

    let(:webhook_params) do
      {
        'signature' => {
          'timestamp' => timestamp,
          'token' => token,
          'signature' => signature
        },
        'event-data' => {
          'id' => SecureRandom.hex(16),
          'event' => 'delivered',
          'timestamp' => Time.current.to_f,
          'recipient' => 'user@example.com',
          'message' => {
            'headers' => {
              'message-id' => 'test-message-id@mail.example.com'
            }
          }
        }
      }
    end

    def do_request(params = webhook_params)
      post '/admin/mailer-log/webhooks/mailgun', params: params
    end

    context 'with valid signature' do
      it 'returns ok status' do
        email # ensure email exists

        do_request

        expect(response).to have_http_status(:ok)
      end

      it 'creates an event for the email' do
        email # ensure email exists

        expect { do_request }.to change(MailerLog::Event, :count).by(1)

        event = MailerLog::Event.last
        expect(event.email).to eq(email)
        expect(event.event_type).to eq('delivered')
        expect(event.recipient).to eq('user@example.com')
      end

      it 'updates email status' do
        email # ensure email exists

        do_request

        expect(email.reload.status).to eq('delivered')
        expect(email.delivered_at).to be_present
      end

      context 'when email not found' do
        let(:webhook_params) do
          {
            'signature' => {
              'timestamp' => timestamp,
              'token' => token,
              'signature' => signature
            },
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
          }
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
              {
                'signature' => {
                  'timestamp' => timestamp,
                  'token' => token,
                  'signature' => signature
                },
                'event-data' => {
                  'id' => SecureRandom.hex(16),
                  'event' => event_type,
                  'timestamp' => Time.current.to_f,
                  'recipient' => 'user@example.com',
                  'message' => {
                    'headers' => {
                      'message-id' => 'test-message-id@mail.example.com'
                    }
                  }
                }
              }
            end

            it "creates #{event_type} event" do
              email # ensure email exists

              expect { do_request }.to change(MailerLog::Event, :count).by(1)

              expect(MailerLog::Event.last.event_type).to eq(event_type)
            end
          end
        end
      end

      context 'with permanent_fail event' do
        let(:webhook_params) do
          {
            'signature' => {
              'timestamp' => timestamp,
              'token' => token,
              'signature' => signature
            },
            'event-data' => {
              'id' => SecureRandom.hex(16),
              'event' => 'permanent_fail',
              'timestamp' => Time.current.to_f,
              'recipient' => 'user@example.com',
              'message' => {
                'headers' => {
                  'message-id' => 'test-message-id@mail.example.com'
                }
              }
            }
          }
        end

        it 'normalizes to bounced event type' do
          email # ensure email exists

          do_request

          expect(MailerLog::Event.last.event_type).to eq('bounced')
          expect(email.reload.status).to eq('bounced')
        end
      end

      context 'with duplicate event' do
        let(:event_id) { 'duplicate-event-id' }
        let(:webhook_params) do
          {
            'signature' => {
              'timestamp' => timestamp,
              'token' => token,
              'signature' => signature
            },
            'event-data' => {
              'id' => event_id,
              'event' => 'delivered',
              'timestamp' => Time.current.to_f,
              'recipient' => 'user@example.com',
              'message' => {
                'headers' => {
                  'message-id' => 'test-message-id@mail.example.com'
                }
              }
            }
          }
        end

        it 'deduplicates and returns ok' do
          email # ensure email exists

          # First request
          do_request
          expect(MailerLog::Event.count).to eq(1)

          # Second request with same event_id
          do_request
          expect(MailerLog::Event.count).to eq(1)

          expect(response).to have_http_status(:ok)
        end
      end

      context 'with tracking_id header' do
        let(:email) { create(:mailer_log_email) }

        let(:webhook_params) do
          {
            'signature' => {
              'timestamp' => timestamp,
              'token' => token,
              'signature' => signature
            },
            'event-data' => {
              'id' => SecureRandom.hex(16),
              'event' => 'delivered',
              'timestamp' => Time.current.to_f,
              'recipient' => 'user@example.com',
              'message' => {
                'headers' => {
                  # Use the email's actual tracking_id
                  'x-mailer-log-tracking-id' => email.tracking_id
                }
              }
            }
          }
        end

        it 'finds email by tracking_id' do
          email # ensure email exists

          expect { do_request }.to change(MailerLog::Event, :count).by(1)

          expect(MailerLog::Event.last.email).to eq(email)
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
