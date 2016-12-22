class ActionRouter
  def initialize(app)
    @app = app
  end

  def call(env)
    input = env['rack.input']
    body = input.read

    unless body.blank?
      relative_path = JSON.parse(input.read).with_indifferent_access[:result][:action]
      env['PATH_INFO'] += relative_path
    end

    input.rewind
    @app.call(env)
  end
end
