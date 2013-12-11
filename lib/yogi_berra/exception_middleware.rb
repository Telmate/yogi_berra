module YogiBerra
  class ExceptionMiddleware
    def initialize(app)
      @app = app
      YogiBerra::Catcher.connect(true)
    end

    def call(env)
      begin
        path_parameters = env['action_controller.request.path_parameters'] || {}
        query_hash      = env['rack.request.query_hash'] || {}
        environment = {
          :session => env['rack.session'],
          :params => path_parameters.merge(query_hash),
          :user_agent => env['HTTP_USER_AGENT'],
          :server_name => env['SERVER_NAME'],
          :server_port => env['SERVER_PORT'],
          :server_address => env['SERVER_ADDR'],
          :remote_address => env['REMOTE_ADDR']
        }
        response = dup._call(env)
      rescue Exception => raised
        YogiBerra.exceptionize(raised, environment)
        raise raised
      end

      if env['rack.exception']
        YogiBerra.exceptionize(raised, environment)
      end
      response
    end

    def _call(env)
      @status, @headers, @response = @app.call(env)
      [@status, @headers, self]
    end

    def each(&block)
      @response.each(&block)
    end

  end
end
