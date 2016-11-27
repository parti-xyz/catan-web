module V1
  module Defaults
    extend ActiveSupport::Concern

    included do
      default_format :json
      format :json
      # formatter :json,
      #   Grape::Formatter::ActiveModelSerializers
      use GrapeLogging::Middleware::RequestLogger,
        instrumentation_key: 'grape_key',
        include: [ GrapeLogging::Loggers::Response.new,
                   GrapeLogging::Loggers::ClientEnv.new,
                   GrapeLogging::Loggers::RequestHeaders.new,
                   GrapeLogging::Loggers::FilterParameters.new ]

      route :any, '*path' do
        error!({ error:  'Not Implemented',
                 detail: "No such route '#{request.path}'",
                 status: '501' },
                 501)
      end

      # Generate a properly formatted 404 error for '/'
      route :any do
        error!({ error:  'Not Implemented',
                 detail: "No such route '#{request.path}'",
                 status: '501' },
                 501)
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        logger.info "404"
        logger.error e.message
        logger.error e.backtrace.join("\n")
        error!(e.message, 404)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        logger.info "422"
        logger.error e.message
        logger.error e.backtrace.join("\n")
        error!(e.message, 422)
      end

      rescue_from Grape::Exceptions::ValidationErrors do |e|
        logger.info "400"
        logger.error e.message
        logger.error e.backtrace.join("\n")
        error!(e.message, 400)
      end

      rescue_from WineBouncer::Errors::OAuthUnauthorizedError do |e|
        logger.info "501"
        error!(e.message, 501)
      end

      unless Rails.env.development?
        rescue_from :all do |e|
          logger.error e.message
          logger.error e.backtrace.join("\n")
          logger.info "500"
          ExceptionNotifier.notify_exception(e)
          error!(e.message, 500)
        end
      end
    end
  end
end
