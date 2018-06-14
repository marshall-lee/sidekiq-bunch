# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/postpone'

class Sidekiq::Bunch
  require 'sidekiq/bunch/version'
  require 'sidekiq/bunch/middleware'
  require 'sidekiq/bunch/worker'

  TimeoutError = Class.new(StandardError)

  def self.generate_bunch_id
    SecureRandom.hex(12)
  end

  def initialize(bunch_id = self.class.generate_bunch_id)
    @bunch_id = bunch_id
    @jids_key = build_jids_key
  end

  def hook(ignore: nil)
    Thread.current[:sidekiq_bunch] = self
    Sidekiq::Postpone.wrap(join_parent: false, flush: false) do |postpone|
      yield
      jids =
        if ignore
          postpone.all_jobs.reject(&ignore).map { |j| j['jid'] }
        else
          postpone.jids
        end
      multi do
        add(jids)
        postpone.flush!
      end
    end
  ensure
    Thread.current[:sidekiq_bunch] = nil
  end

  def on_success(job)
    rem(job['jid'])
  end

  def add(jids)
    jids = Array(jids)

    redis do |r|
      r.sadd(@jids_key, jids)
    end
  end

  def rem(jids)
    jids = Array(jids)

    redis do |r|
      r.srem(@jids_key, jids)
    end
  end

  def size
    redis { |r| r.scard(@jids_key) }
  end

  def empty?
    0 == size
  end

  def wait_for_empty(poll_interval: 1.0, timeout: nil)
    start_time = Time.now if timeout
    loop do
      break if empty?
      raise TimeoutError if timeout && (Time.now - start_time) >= timeout
      sleep(poll_interval)
    end
  end

  attr_reader :bunch_id

  private

  def build_jids_key
    "bunches:#{@bunch_id}-jids"
  end

  def redis
    Sidekiq.redis { |r| yield r }
  end

  def multi
    redis { |r| r.multi { |m| yield m } }
  end
end
