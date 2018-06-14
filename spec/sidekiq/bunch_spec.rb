RSpec.describe Sidekiq::Bunch do
  before do
    sidekiq_worker(:Foo)
  end

  let(:default_queue) { Sidekiq::Queue.new(:default) }
  let(:bar_queue) { Sidekiq::Queue.new(:bar) }

  let(:bunch_id) { 'buu' }
  let(:bunch) { described_class.new(bunch_id) }
  subject { bunch }

  def fetch_bunch_jids
    Sidekiq.redis { |r| r.smembers('bunches:buu-jids') }
  end

  describe '#hook' do
    it 'pushes jobs performed inside the block to redis' do
      jids = []
      Foo.perform_async
      bunch.hook do
        jids << Foo.perform_async
        jids << Foo.perform_async
      end
      Foo.perform_async
      expect(fetch_bunch_jids).to contain_exactly(*jids)
    end

    it 'pushes jobs to the queue and assigns bunch_id metadata' do
      jids = []
      Foo.perform_async
      bunch.hook do
        jids << Foo.perform_async
        jids << Foo.perform_async
      end
      jobs = default_queue.to_a.reverse
      expect(jobs.map(&:jid)).to include(*jids)
      expect(jobs.map { |j| j['bunch_id'] }).to eq [nil, bunch_id, bunch_id]
    end

    it 'is able to ignore particular jobs with :ignore lambda' do
      sidekiq_worker(:Bar) do
        sidekiq_options queue: :bar
      end

      jids = []

      bunch.hook(ignore: ->(j) { j['queue'] == 'bar' }) do
        jids << Foo.perform_async
        jids << Bar.perform_async
      end
      expect(default_queue.map(&:jid)).to include(jids[0])
      expect(bar_queue.map(&:jid)).to include(jids[1])

      bunch_jids = fetch_bunch_jids
      expect(bunch_jids).to include(jids[0])
      expect(bunch_jids).not_to include(jids[1])
    end
  end

  describe '#empty?' do
    it 'is empty by default' do
      is_expected.to be_empty
    end

    it 'is not empty after adding the jobs' do
      bunch.hook { Foo.perform_async }
      is_expected.not_to be_empty
    end
  end

  describe '#size' do
    it 'is equal to actual count of pushed jobs' do
      expect(bunch.size).to eq 0
      Foo.perform_async
      bunch.hook do
        Foo.perform_async
      end
      expect(bunch.size).to eq 1
      bunch.hook do
        Foo.perform_async
        Foo.perform_async
      end
      expect(bunch.size).to eq 3
    end
  end

  describe '#wait_for_empty' do
    around { |ex| Sidekiq::Testing.fake!(&ex) }

    before do
      sidekiq_worker :Sleeper do
        def perform(t)
          sleep(t)
        end
      end

      bunch.hook { Sleeper.perform_async(0.3) }
      Thread.new { Sleeper.drain }
    end

    it 'waits for the jobs to be completed when timeout is not specified' do
      bunch.wait_for_empty(poll_interval: 0.1)
      expect(bunch).to be_empty
    end

    it 'waits for the jobs to be completed' do
      bunch.wait_for_empty(poll_interval: 0.1, timeout: 0.4)
      expect(bunch).to be_empty
    end

    it 'raises timeout error if timeout is reached' do
      expect { bunch.wait_for_empty(poll_interval: 0.1, timeout: 0.2) }
        .to raise_error(described_class::TimeoutError)
    end
  end
end
