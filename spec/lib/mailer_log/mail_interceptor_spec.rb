# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MailerLog::MailInterceptor do
  let(:message) { Mail.new }

  before do
    MailerLog::Current.reset

    message.from = 'sender@example.com'
    message.to = ['recipient@example.com']
    message.subject = 'Test Subject'
    message.body = 'Test body content'

    allow(MailerLog.configuration).to receive(:capture_call_stack).and_return(false)
  end

  describe '.delivering_email' do
    it 'adds tracking header to message' do
      described_class.delivering_email(message)

      expect(message.header['X-Mailer-Log-Tracking-ID'].value).to be_present
      expect(message.header['X-Mailer-Log-Tracking-ID'].value).to match(/\A[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}\z/i)
    end

    it 'stores email data in CurrentAttributes' do
      described_class.delivering_email(message)

      data = MailerLog::Current.email_data
      expect(data).to be_present
      expect(data[:from_address]).to eq('sender@example.com')
      expect(data[:to_addresses]).to eq(['recipient@example.com'])
      expect(data[:subject]).to eq('Test Subject')
    end

    it 'stores tracking_id matching header' do
      described_class.delivering_email(message)

      data = MailerLog::Current.email_data
      expect(data[:tracking_id]).to eq(message.header['X-Mailer-Log-Tracking-ID'].value)
    end

    context 'with multipart email' do
      before do
        message.html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body '<h1>Hello</h1>'
        end

        message.text_part = Mail::Part.new do
          content_type 'text/plain; charset=UTF-8'
          body 'Hello'
        end
      end

      it 'extracts html and text parts' do
        described_class.delivering_email(message)

        data = MailerLog::Current.email_data
        expect(data[:html_body]).to eq('<h1>Hello</h1>')
        expect(data[:text_body]).to eq('Hello')
      end
    end

    context 'with cc and bcc recipients' do
      before do
        message.cc = ['cc@example.com']
        message.bcc = ['bcc@example.com']
      end

      it 'stores cc and bcc addresses' do
        described_class.delivering_email(message)

        data = MailerLog::Current.email_data
        expect(data[:cc_addresses]).to eq(['cc@example.com'])
        expect(data[:bcc_addresses]).to eq(['bcc@example.com'])
      end
    end

    context 'with multiple recipients' do
      before do
        message.to = ['user1@example.com', 'user2@example.com']
      end

      it 'stores all recipients' do
        described_class.delivering_email(message)

        data = MailerLog::Current.email_data
        expect(data[:to_addresses]).to eq(['user1@example.com', 'user2@example.com'])
      end
    end

    context 'with call stack capture enabled' do
      before do
        allow(MailerLog.configuration).to receive(:capture_call_stack).and_return(true)
        allow(MailerLog.configuration).to receive(:call_stack_depth).and_return(5)
      end

      it 'captures call stack' do
        described_class.delivering_email(message)

        data = MailerLog::Current.email_data
        # Call stack should be present but may be empty depending on Rails.root
        expect(data).to have_key(:call_stack)
      end
    end

    context 'when error occurs' do
      before do
        allow(message).to receive(:from).and_raise(StandardError.new('Test error'))
      end

      it 'logs error and does not raise' do
        expect(Rails.logger).to receive(:error).at_least(:once)

        expect { described_class.delivering_email(message) }.not_to raise_error
      end
    end

    context 'with headers extraction' do
      before do
        message.header['X-Custom-Header'] = 'custom_value'
      end

      it 'extracts all headers' do
        described_class.delivering_email(message)

        data = MailerLog::Current.email_data
        expect(data[:headers]).to be_a(Hash)
        expect(data[:headers]['X-Custom-Header']).to eq('custom_value')
      end
    end
  end
end
