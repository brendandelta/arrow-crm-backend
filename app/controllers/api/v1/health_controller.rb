module Api
  module V1
    class HealthController < ApplicationController
      def show
        render json: { ok: true }
      end
    end
  end
end
