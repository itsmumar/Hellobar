# Read method definition from file for now since queue_worker is in a bin file
class QueueWorkerMock
  queue_worker = File.expand_path('bin/queue_worker')
  body = []
  open = false
  File.open(queue_worker).each do |line|
    break if open && line.strip == 'end'
    body << line.strip if open
    open = true if line.strip.index('def parse_message') == 0
  end

  instance_eval <<-EOS
    def parse_message_from_executable(message)
      #{ body.join('; ') }
    end
  EOS

  def self.parse_message(message)
    parse_message_from_executable(message)
  end
end

require 'csv'

describe QueueWorkerMock, 'queue worker spec' do
  context '#parse_message' do
    let(:message) { double(:message, body: body) }
    let(:id) { '12345' }
    let(:email) { 'test@test.com' }

    subject { described_class.parse_message(message) }

    context 'body has bang' do
      context 'with one argument' do
        let(:body) { 'contact_list:sync_all![12345]' }
        it { should eq ['contact_list', 'sync_all!', id] }
      end
      context 'with two arguments' do
        let(:body) { 'contact_list:sync_one![12345,test@test.com]' }
        it { should eq ['contact_list', 'sync_one!', id, email] }
      end
      context 'with no arguments' do
        let(:body) { 'contact_list:sync_one!' }
        it { should eq ['contact_list', 'sync_one!'] }
      end
    end

    context 'body has question mark' do
      context 'with one argument' do
        let(:body) { 'contact_list:sync?[12345]' }
        it { should eq ['contact_list', 'sync?', id] }
      end
      context 'with two arguments' do
        let(:body) { 'contact_list:sync?[12345,test@test.com]' }
        it { should eq ['contact_list', 'sync?', id, email] }
      end
      context 'with no arguments' do
        let(:body) { 'contact_list:sync?' }
        it { should eq ['contact_list', 'sync?'] }
      end
    end

    context 'body has special class' do
      context 'with one argument' do
        let(:body) { 'hellobar::contact_list:sync![12345]' }
        it { should eq ['hellobar::contact_list', 'sync!', id] }
      end
      context 'with two arguments' do
        let(:body) { 'hellobar::contact_list:sync_one![12345,test@test.com]' }
        it { should eq ['hellobar::contact_list', 'sync_one!', id, email] }
      end
      context 'with no arguments' do
        let(:body) { 'hellobar::contact_list:sync' }
        it { should eq ['hellobar::contact_list', 'sync'] }
      end
    end
  end
end
