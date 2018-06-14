# frozen_string_literal: true

require 'sidekiq/worker'

class Sidekiq::Bunch
  module Worker
    attr_accessor :bunch_id

    def bunch
      @bunch ||= Sidekiq::Bunch.new(bunch_id) if bunch_id
    end
  end

  Sidekiq::Worker.prepend Worker
end
