# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'mailer_log:install_assets' do
  before(:all) do
    Rails.application.load_tasks
  end

  let(:task) { Rake::Task['mailer_log:install_assets'] }
  let(:source_dir) { MailerLog::Engine.root.join('public', 'mailer_log') }
  let(:destination_dir) { Rails.root.join('public', 'assets', 'mailer_log') }

  before do
    task.reenable
    FileUtils.rm_rf(destination_dir) if destination_dir.exist?
  end

  after do
    FileUtils.rm_rf(destination_dir) if destination_dir.exist?
  end

  it 'copies assets to public/assets/mailer_log' do
    expect { task.invoke }.to output(/MailerLog assets copied/).to_stdout

    expect(destination_dir).to exist
    expect(destination_dir.join('.vite', 'manifest.json')).to exist
    expect(destination_dir.join('index.html')).to exist
  end

  it 'copies assets directory with JS and CSS files' do
    task.invoke

    assets_dir = destination_dir.join('assets')
    expect(assets_dir).to exist

    js_files = Dir[assets_dir.join('*.js')]
    css_files = Dir[assets_dir.join('*.css')]

    expect(js_files).not_to be_empty
    expect(css_files).not_to be_empty
  end

  it 'removes existing destination before copying' do
    FileUtils.mkdir_p(destination_dir)
    old_file = destination_dir.join('old_file.txt')
    File.write(old_file, 'old content')

    task.invoke

    expect(old_file).not_to exist
  end

  context 'when source does not exist' do
    before do
      allow(MailerLog::Engine).to receive(:root).and_return(Pathname.new('/nonexistent'))
    end

    it 'exits with error' do
      expect { task.invoke }.to output(/ERROR: MailerLog assets not found/).to_stdout
        .and raise_error(SystemExit)
    end
  end
end
