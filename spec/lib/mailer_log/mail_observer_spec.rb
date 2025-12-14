# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MailerLog::MailObserver do
  let(:message) { Mail.new }
  let(:message_id) { 'unique-message-id@mail.example.com' }

  let(:interceptor_data) do
    {
      tracking_id: SecureRandom.uuid,
      mailer_class: 'TestMailer',
      mailer_action: 'welcome',
      from_address: 'sender@example.com',
      to_addresses: ['recipient@example.com'],
      cc_addresses: [],
      bcc_addresses: [],
      subject: 'Test Subject',
      html_body: '<h1>Hello</h1>',
      text_body: 'Hello',
      headers: { 'X-Mailer' => 'Rails' },
      call_stack: nil,
      domain: 'example.com'
    }
  end

  before do
    MailerLog::Current.email_data = interceptor_data
    allow(message).to receive(:message_id).and_return(message_id)
    allow(MailerLog.configuration).to receive(:resolve_accountable_proc).and_return(nil)
  end

  after do
    MailerLog::Current.reset
  end

  describe '.delivered_email' do
    it 'creates email record from thread data' do
      expect { described_class.delivered_email(message) }.to change(MailerLog::Email, :count).by(1)

      email = MailerLog::Email.last
      expect(email.tracking_id).to eq(interceptor_data[:tracking_id])
      expect(email.mailer_class).to eq('TestMailer')
      expect(email.mailer_action).to eq('welcome')
      expect(email.from_address).to eq('sender@example.com')
      expect(email.to_addresses).to eq(['recipient@example.com'])
      expect(email.subject).to eq('Test Subject')
      expect(email.message_id).to eq(message_id)
      expect(email.status).to eq('sent')
    end

    it 'clears CurrentAttributes after processing' do
      described_class.delivered_email(message)

      expect(MailerLog::Current.email_data).to be_nil
    end

    context 'when no interceptor data present' do
      before do
        MailerLog::Current.reset
      end

      it 'does not create email record' do
        expect { described_class.delivered_email(message) }.not_to change(MailerLog::Email, :count)
      end
    end

    context 'with accountable resolver configured' do
      let(:organization) { crank!(:organization) }
      let(:resolver) { ->(email) { organization } }

      before do
        allow(MailerLog.configuration).to receive(:resolve_accountable_proc).and_return(resolver)
      end

      it 'associates email with accountable' do
        described_class.delivered_email(message)

        email = MailerLog::Email.last
        expect(email.accountable).to eq(organization)
      end
    end

    context 'when accountable resolver raises error' do
      let(:resolver) { ->(_email) { raise StandardError, 'Resolver error' } }

      before do
        allow(MailerLog.configuration).to receive(:resolve_accountable_proc).and_return(resolver)
      end

      it 'still creates email record without accountable' do
        expect(Rails.logger).to receive(:warn).with(/Failed to resolve accountable/)

        expect { described_class.delivered_email(message) }.to change(MailerLog::Email, :count).by(1)

        expect(MailerLog::Email.last.accountable).to be_nil
      end
    end

    context 'when save fails' do
      before do
        allow_any_instance_of(MailerLog::Email).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'logs error and does not raise' do
        expect(Rails.logger).to receive(:error).at_least(:once)

        expect { described_class.delivered_email(message) }.not_to raise_error
      end

      it 'clears CurrentAttributes even on error' do
        described_class.delivered_email(message)

        expect(MailerLog::Current.email_data).to be_nil
      end
    end

    context 'with html and text bodies' do
      before do
        interceptor_data[:html_body] = '<html><body><h1>Welcome</h1></body></html>'
        interceptor_data[:text_body] = 'Welcome'
        MailerLog::Current.email_data = interceptor_data
      end

      it 'stores both body types' do
        described_class.delivered_email(message)

        email = MailerLog::Email.last
        expect(email.html_body).to eq('<html><body><h1>Welcome</h1></body></html>')
        expect(email.text_body).to eq('Welcome')
      end
    end

    context 'with call stack' do
      before do
        interceptor_data[:call_stack] = ['/app/controllers/users_controller.rb:25', '/app/services/mailer_service.rb:10']
        MailerLog::Current.email_data = interceptor_data
      end

      it 'stores call stack' do
        described_class.delivered_email(message)

        email = MailerLog::Email.last
        expect(email.call_stack).to include('/app/controllers/users_controller.rb:25')
      end
    end
  end
end
