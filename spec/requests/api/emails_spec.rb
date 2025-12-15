# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MailerLog::Api::EmailsController, type: :request do
  let(:admin_user) { crank!(:user, email: 'team@localviking.com') }

  before { sign_in(admin_user) }

  describe 'GET #index' do
    let!(:email1) { create(:mailer_log_email, subject: 'Welcome Email', mailer_class: 'UsersMailer', created_at: 2.days.ago) }
    let!(:email2) { create(:mailer_log_email, subject: 'Password Reset', mailer_class: 'DeviseMailer', created_at: 1.day.ago) }
    let!(:email3) { create(:mailer_log_email, subject: 'Invoice', to_addresses: ['billing@example.com'], created_at: 1.hour.ago) }

    def do_request(params = {})
      get '/admin/mailer-log/api/emails', params: params
    end

    it 'returns a successful JSON response' do
      do_request

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
    end

    it 'returns emails ordered by created_at desc' do
      do_request

      json = JSON.parse(response.body)
      expect(json['emails'].length).to eq(3)
      expect(json['emails'][0]['subject']).to eq('Invoice')
      expect(json['emails'][1]['subject']).to eq('Password Reset')
      expect(json['emails'][2]['subject']).to eq('Welcome Email')
    end

    it 'returns pagination info' do
      do_request

      json = JSON.parse(response.body)
      expect(json['total_count']).to eq(3)
      expect(json['total_pages']).to eq(1)
      expect(json['current_page']).to eq(1)
    end

    it 'returns email attributes without body' do
      do_request

      json = JSON.parse(response.body)
      email_json = json['emails'].find { |e| e['subject'] == 'Welcome Email' }

      expect(email_json['id']).to eq(email1.id)
      expect(email_json['mailer_class']).to eq('UsersMailer')
      expect(email_json['mailer_action']).to eq('welcome')
      expect(email_json['from_address']).to eq('noreply@example.com')
      expect(email_json['status']).to eq('sent')
      expect(email_json).not_to have_key('html_body')
      expect(email_json).not_to have_key('text_body')
    end

    context 'with recipient filter' do
      it 'filters emails by recipient' do
        do_request(recipient: 'billing@example.com')

        json = JSON.parse(response.body)
        expect(json['emails'].length).to eq(1)
        expect(json['emails'][0]['subject']).to eq('Invoice')
      end
    end

    context 'with sender filter' do
      let!(:email_from_other) { create(:mailer_log_email, from_address: 'other@example.com', subject: 'From Other') }

      it 'filters emails by sender' do
        do_request(sender: 'other@example.com')

        json = JSON.parse(response.body)
        expect(json['emails'].length).to eq(1)
        expect(json['emails'][0]['subject']).to eq('From Other')
      end
    end

    context 'with mailer filter' do
      it 'filters emails by mailer class' do
        do_request(mailer: 'DeviseMailer')

        json = JSON.parse(response.body)
        expect(json['emails'].length).to eq(1)
        expect(json['emails'][0]['subject']).to eq('Password Reset')
      end
    end

    context 'with status filter' do
      let!(:delivered_email) { create(:mailer_log_email, :delivered, subject: 'Delivered Email') }
      let!(:bounced_email) { create(:mailer_log_email, :bounced, subject: 'Bounced Email') }

      it 'filters emails by status' do
        do_request(status: 'bounced')

        json = JSON.parse(response.body)
        expect(json['emails'].length).to eq(1)
        expect(json['emails'][0]['subject']).to eq('Bounced Email')
      end
    end

    context 'with subject search' do
      it 'filters emails by subject' do
        do_request(subject_search: 'Password')

        json = JSON.parse(response.body)
        expect(json['emails'].length).to eq(1)
        expect(json['emails'][0]['subject']).to eq('Password Reset')
      end
    end

    context 'with date filters' do
      it 'filters emails by date_from' do
        do_request(date_from: 1.day.ago.to_date.to_s)

        json = JSON.parse(response.body)
        expect(json['emails'].length).to eq(2)
        subjects = json['emails'].map { |e| e['subject'] }
        expect(subjects).to include('Invoice', 'Password Reset')
        expect(subjects).not_to include('Welcome Email')
      end

      it 'filters emails by date_to' do
        do_request(date_to: 1.day.ago.to_date.to_s)

        json = JSON.parse(response.body)
        subjects = json['emails'].map { |e| e['subject'] }
        expect(subjects).to include('Welcome Email')
      end
    end

    context 'with pagination' do
      before do
        30.times { |i| create(:mailer_log_email, subject: "Email #{i}") }
      end

      it 'paginates results with default per page' do
        do_request

        json = JSON.parse(response.body)
        expect(json['emails'].length).to eq(25)
        expect(json['total_count']).to eq(33)
        expect(json['total_pages']).to eq(2)
      end

      it 'respects custom per page' do
        do_request(per: 10)

        json = JSON.parse(response.body)
        expect(json['emails'].length).to eq(10)
        expect(json['total_pages']).to eq(4)
      end

      it 'navigates to specific page' do
        do_request(page: 2, per: 10)

        json = JSON.parse(response.body)
        expect(json['current_page']).to eq(2)
        expect(json['emails'].length).to eq(10)
      end
    end
  end

  describe 'GET #show' do
    let!(:email) do
      create(:mailer_log_email,
        subject: 'Test Email',
        html_body: '<h1>Hello World</h1>',
        text_body: 'Hello World',
        call_stack: ['/app/controllers/users_controller.rb:25']
      )
    end
    let!(:event1) { create(:mailer_log_event, email: email, event_type: 'delivered', occurred_at: 1.hour.ago) }
    let!(:event2) { create(:mailer_log_event, :opened, email: email, occurred_at: 30.minutes.ago) }

    def do_request
      get "/admin/mailer-log/api/emails/#{email.id}"
    end

    it 'returns a successful JSON response' do
      do_request

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
    end

    it 'returns email details with body' do
      do_request

      json = JSON.parse(response.body)
      email_json = json['email']

      expect(email_json['id']).to eq(email.id)
      expect(email_json['subject']).to eq('Test Email')
      expect(email_json['html_body']).to eq('<h1>Hello World</h1>')
      expect(email_json['text_body']).to eq('Hello World')
      expect(email_json['headers']).to be_a(Hash)
    end

    it 'includes call stack' do
      do_request

      json = JSON.parse(response.body)
      expect(json['email']['call_stack']).to include('/app/controllers/users_controller.rb:25')
    end

    it 'includes events ordered by occurred_at desc' do
      do_request

      json = JSON.parse(response.body)
      events = json['email']['events']

      expect(events.length).to eq(2)
      expect(events[0]['event_type']).to eq('opened')
      expect(events[1]['event_type']).to eq('delivered')
    end

    it 'includes event details' do
      do_request

      json = JSON.parse(response.body)
      event = json['email']['events'][0]

      expect(event['id']).to be_present
      expect(event['event_type']).to eq('opened')
      expect(event['occurred_at']).to be_present
      expect(event['recipient']).to be_present
    end

    context 'when email not found' do
      it 'returns 404' do
        get '/admin/mailer-log/api/emails/999999'

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context 'when user is not admin' do
    let(:organization) { crank!(:organization) }
    let(:regular_user) { crank!(:user, email: 'regular@example.com', organization: organization) }

    before { sign_in(regular_user) }

    it 'denies access to index' do
      get '/admin/mailer-log/api/emails'

      expect(response).to have_http_status(:found).or have_http_status(:forbidden)
    end

    it 'denies access to show' do
      email = create(:mailer_log_email)
      get "/admin/mailer-log/api/emails/#{email.id}"

      expect(response).to have_http_status(:found).or have_http_status(:forbidden)
    end
  end
end
