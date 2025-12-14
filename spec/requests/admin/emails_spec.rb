# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MailerLog::Admin::EmailsController, type: :request do
  let(:admin_user) { crank!(:user, email: 'team@localviking.com') }

  before { sign_in(admin_user) }

  describe 'GET #index' do
    let!(:email1) { create(:mailer_log_email, subject: 'Welcome Email', mailer_class: 'UsersMailer') }
    let!(:email2) { create(:mailer_log_email, subject: 'Password Reset', mailer_class: 'DeviseMailer') }
    let!(:email3) { create(:mailer_log_email, subject: 'Invoice', to_addresses: ['billing@example.com']) }

    def do_request(params = {})
      get '/admin/email_log/admin/emails', params: params
    end

    it 'returns a successful response' do
      do_request

      expect(response).to have_http_status(:ok)
    end

    it 'displays all emails' do
      do_request

      expect(response.body).to include('Welcome Email')
      expect(response.body).to include('Password Reset')
      expect(response.body).to include('Invoice')
    end

    context 'with recipient filter' do
      it 'filters emails by recipient' do
        do_request(recipient: 'billing@example.com')

        expect(response.body).to include('Invoice')
        expect(response.body).not_to include('Welcome Email')
      end
    end

    context 'with mailer filter' do
      it 'filters emails by mailer class' do
        do_request(mailer: 'UsersMailer')

        expect(response.body).to include('Welcome Email')
        expect(response.body).not_to include('Password Reset')
      end
    end

    context 'with status filter' do
      let!(:delivered_email) { create(:mailer_log_email, :delivered, subject: 'Delivered Email') }
      let!(:bounced_email) { create(:mailer_log_email, :bounced, subject: 'Bounced Email') }

      it 'filters emails by status' do
        do_request(status: 'bounced')

        expect(response.body).to include('Bounced Email')
        expect(response.body).not_to include('Delivered Email')
      end
    end

    context 'with subject search' do
      it 'filters emails by subject' do
        do_request(subject_search: 'Password')

        expect(response.body).to include('Password Reset')
        expect(response.body).not_to include('Welcome Email')
        expect(response.body).not_to include('Invoice')
      end
    end

    context 'with pagination' do
      before do
        30.times { |i| create(:mailer_log_email, subject: "Email #{i}") }
      end

      it 'paginates results' do
        do_request(per: 10)

        expect(response.body).to include('Email 29')
        expect(response.body).not_to include('Email 0')
      end

      it 'navigates to specific page' do
        do_request(page: 2, per: 10)

        expect(response.body).to include('Email 19')
      end
    end
  end

  describe 'GET #show' do
    let!(:email) { create(:mailer_log_email, subject: 'Test Email', html_body: '<h1>Hello World</h1>') }
    let!(:event) { create(:mailer_log_event, email: email, event_type: 'delivered') }

    def do_request
      get "/admin/email_log/admin/emails/#{email.id}"
    end

    it 'returns a successful response' do
      do_request

      expect(response).to have_http_status(:ok)
    end

    it 'displays email details' do
      do_request

      expect(response.body).to include('Test Email')
      expect(response.body).to include('UsersMailer')
    end

    it 'displays email events' do
      do_request

      expect(response.body).to include('delivered')
    end
  end

  describe 'GET #preview' do
    let!(:email) { create(:mailer_log_email, html_body: '<html><body><h1>Email Preview</h1></body></html>') }

    def do_request
      get "/admin/email_log/admin/emails/#{email.id}/preview"
    end

    it 'returns a successful response' do
      do_request

      expect(response).to have_http_status(:ok)
    end

    it 'renders raw HTML without layout' do
      do_request

      expect(response.body).to eq('<html><body><h1>Email Preview</h1></body></html>')
    end
  end

  context 'when user is not admin' do
    let(:organization) { crank!(:organization) }
    let(:regular_user) { crank!(:user, email: 'regular@example.com', organization: organization) }

    before { sign_in(regular_user) }

    it 'denies access to index' do
      get '/admin/email_log/admin/emails'

      # Non-admin users get redirected to login or error page
      expect(response).to have_http_status(:found).or have_http_status(:forbidden)
    end
  end
end
