# frozen_string_literal: true

module Sidekiq::Bunch::Middleware
  class Client
    def call(_worker_class, msg, _queue, _redis_pool)
      bunch = Thread.current[:sidekiq_bunch]
      msg['bunch_id'] = bunch.bunch_id if bunch
      yield
    end
  end

  class Server
    def call(worker, msg, _queue)
      bunch_id = msg['bunch_id']
      if bunch_id
        worker.bunch_id = bunch_id
        result = yield
        Sidekiq::Bunch.new(bunch_id).on_success(msg)
        result
      else
        yield
      end
    end
  end

  Sidekiq.configure_client do |config|
    config.client_middleware do |chain|
      chain.add Client
    end
  end

  Sidekiq.configure_server do |config|
    config.client_middleware do |chain|
      chain.add Client
    end

    config.server_middleware do |chain|
      chain.add Server
    end
  end
end
