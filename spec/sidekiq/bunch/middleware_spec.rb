RSpec.describe Sidekiq::Bunch::Middleware::Server do
  around { |ex| Sidekiq::Testing.fake!(&ex) }

  before do
    sidekiq_worker :Foo do
      def perform
      end
    end
  end

  let(:bunch) { Sidekiq::Bunch.new }

  it 'removes jobs from set after finishing' do
    bunch.hook do
      Foo.perform_async
      Foo.perform_async
    end
    expect { Foo.drain }.to change { bunch.empty? }.to true
  end

  it 'assigns proper #bunch_id to the worker' do
    bunch_id = nil

    sidekiq_worker(:Bar) do
      define_method(:perform) do
        bunch_id = self.bunch_id
      end
    end

    expect do
      bunch.hook { Bar.perform_async }
      Bar.drain
    end.to change { bunch_id }.to bunch.bunch_id

    expect do
      Bar.perform_async
      Bar.drain
    end.to change { bunch_id }.to nil
  end

  it 'allows cascading jobs' do
    counter = 0

    sidekiq_worker(:Bar) do
      define_method(:perform) do
        counter += 1
      end
    end
    Foo.class_eval do
      define_method(:perform) do
        bunch.hook do
          3.times { Bar.perform_async }
        end
      end
    end
    bunch.hook { 2.times { Foo.perform_async } }
    expect(bunch.size).to eq 2
    Foo.drain
    expect(counter).to eq 0
    expect(bunch.size).to eq 6
    Bar.drain
    expect(bunch).to be_empty
    expect(counter).to eq 6
  end
end
