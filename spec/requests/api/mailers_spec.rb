# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MailerLog::Api::MailersController, type: :request do
  let(:admin_user) { crank!(:user, email: 'team@localviking.com') }

  before { sign_in(admin_user) }

  describe 'GET #index' do
    def do_request
      get '/admin/mailer-log/api/mailers'
    end

    context 'when no emails exist' do
      it 'returns empty array' do
        do_request

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['mailers']).to eq([])
      end
    end

    context 'when emails exist' do
      before do
        create(:mailer_log_email, mailer_class: 'UsersMailer')
        create(:mailer_log_email, mailer_class: 'NotificationsMailer')
        create(:mailer_log_email, mailer_class: 'DeviseMailer')
        create(:mailer_log_email, mailer_class: 'UsersMailer') # duplicate
      end

      it 'returns a successful JSON response' do
        do_request

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')
      end

      it 'returns distinct mailer classes sorted alphabetically' do
        do_request

        json = JSON.parse(response.body)
        expect(json['mailers']).to eq(%w[DeviseMailer NotificationsMailer UsersMailer])
      end

      it 'excludes nil mailer classes' do
        create(:mailer_log_email, mailer_class: nil)

        do_request

        json = JSON.parse(response.body)
        expect(json['mailers']).not_to include(nil)
        expect(json['mailers'].length).to eq(3)
      end
    end
  end

  context 'when user is not admin' do
    let(:organization) { crank!(:organization) }
    let(:regular_user) { crank!(:user, email: 'regular@example.com', organization: organization) }

    before { sign_in(regular_user) }

    it 'denies access' do
      get '/admin/mailer-log/api/mailers'

      expect(response).to have_http_status(:found).or have_http_status(:forbidden)
    end
  end
end
