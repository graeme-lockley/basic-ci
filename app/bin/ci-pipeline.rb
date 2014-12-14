#!/usr/bin/ruby

require 'logger'
require 'yaml'
require 'json'

class Settings
  def initialize(home_dir)
    @file_name = "#{home_dir.nil? ? '.' : home_dir}/.ci-status"

    if File.exists? @file_name
      @config = YAML::load_file @file_name
    else
      reset
    end
  end

  def reset
    @config = {}
    @config['status'] = 'ready'
    @config['start_date'] = Time.new.to_s
    save_settings
  end

  def status
    @config['status']
  end

  def ready?
    status == 'ready'
  end

  def task
    @config['task']
  end

  def save_settings
    @config['date'] = Time.new.to_s
    File.open(@file_name, 'w') { |f| f.write @config.to_yaml }
  end

  def set_state(current_task, status)
    @config['task'] = current_task
    @config['status'] = status
    save_settings
  end

  def complete
    @config.delete 'task'
    @config['status'] = 'complete'
    save_settings
  end

  def show
    puts JSON.dump(@config)
  end
end

class Task
  def self.tasks(pipeline_dir, pipeline_name)
    Dir["#{pipeline_dir}/ci-pipeline/tasks/#{pipeline_name.nil? ? '' : (pipeline_name + '-')}*"].map { |t| Task.new t }
  end

  def initialize(full_name)
    @name = full_name.split('/').last
    @full_name = full_name
  end

  def execute
    log_file_name = @full_name.sub('tasks', 'logs') + '.log'
    start_time = Time.new
    open(log_file_name, 'a') { |f|
      f.puts "Starting Task: #{start_time.to_s}"
    }
    @success = system "(#{@full_name}) 2>&1 | tee -a #{log_file_name} ; ( exit ${PIPESTATUS[0]} )"
    @return_code = $?
    end_time = Time.new
    open(log_file_name, 'a') { |f|
      f.puts "Ending Task: #{end_time.to_s} (#{end_time - start_time}s): Return Code: #{@return_code}"
    }
  end

  def name
    @name
  end

  def full_name
    @full_name
  end

  def errors?
    !@success
  end

  def return_code
    @return_code
  end

  def info
    result = `#{@full_name} info`
    puts result
  end

  def info_map
    s = {}
    result = `#{@full_name} info`
    result_lines = result.split(/\r?\n/)

    if result_lines.length >= 1
      index_of_colon = result_lines[0].index(':')
      if index_of_colon.nil?
        s["task"] = result_lines[0]
      else
        s["task"] = result_lines[0][0 .. (index_of_colon - 1)]
        s["description"] = result_lines[0][(index_of_colon+1) .. result_lines[0].length].strip
      end

      params = result_lines[1 .. result_lines.length].map do |x|
        components = x.split(':').map{|a| a.strip}
        {name: components[1], type: components[2], description: components[3]}
      end
      s["params"] = params if !params.nil? && params.length > 0
    end

    {name: @name, full_name: @full_name}.merge s
  end
end

class Pipeline
  def initialize(pipeline_dir, pipeline_name, listener, settings)
    @pipeline_dir = pipeline_dir
    @pipeline_name = pipeline_name
    @listener = listener
    @settings = settings
  end

  def tasks
    Task.tasks(@pipeline_dir, @pipeline_name)
  end

  def has_tasks?
    !tasks.empty?
  end

  def run
    tasks.each do |task|
      run_task task
    end
    @settings.complete
  end

  def retry
    failed_task = @settings.task

    tasks.each do |task|
      if task.name < failed_task
        @listener.skipping_task task
      else
        run_task task
      end
    end
    @settings.complete
  end

  def run_task(task)
    @listener.start_task task
    @settings.set_state(task.name, 'running')
    task.execute
    @settings.set_state(task.name, task.errors? ? 'failed' : 'success')
    @listener.end_task task
    exit 1 if task.errors?
  end
end

class LoggerListener
  def initialize(logger)
    @logger = logger
  end

  def skipping_task(task)
    @logger.info "Skipping task #{task.name}"
  end

  def start_task(task)
    @logger.info "Running task #{task.name}"
  end

  def end_task(task)
    if task.errors?
      @logger.info "The task #{task.name} failed: returned code: #{task.return_code}"
    else
      @logger.info "The task #{task.name} successfully completed"
    end
  end
end

logger = Logger.new(STDOUT)
pipeline_dir = '.'
pipeline_name = nil

if ARGV.length > 0
  if %w(run status reset retry info json-info).select { |x| x == ARGV[0] }.count == 0
    args = ARGV[0].split(':')
    pipeline_dir = args[0]
    pipeline_name = args[1] if args.length > 1
    ARGV.delete_at 0
  end

  settings = Settings.new(pipeline_dir)
  listener = LoggerListener.new(logger)

  case ARGV[0]
    when 'run'
      if settings.ready?
        phase = Pipeline.new(pipeline_dir, pipeline_name, listener, settings)

        if phase.has_tasks?
          phase.run
        else
          logger.info ' No tasks - pipeline completed'
        end
      else
        logger.error 'The pipeline failed on a previous task and cannot be run.'
        settings.show
        exit 1
      end
    when 'status'
      settings.show
    when 'reset'
      logger.info 'Pipeline has been reset'
      settings.reset
    when 'retry'
      if settings.ready?
        logger.error 'The pipeline is healthy and does not need to be recovered'
      else
        phase = Pipeline.new(pipeline_dir, pipeline_name, listener, settings)

        if phase.has_tasks?
          phase.retry
        else
          logger.info 'No tasks - pipeline completed'
        end
      end
    when 'info'
      Task.tasks(pipeline_dir, pipeline_name).each { |task|
        task.info
      }
    when 'json-info'
      puts Task.tasks(pipeline_dir, pipeline_name).map { |task| task.info_map }.to_json
    else
      logger.error "Unknown command #{ARGV[0]}"
      exit 1
  end
else
  logger.error 'Argument expected: [pipeline_tasks_home[:pipeline_name]] command'
  logger.info 'The pipeline_home is the directory where the pipeline tasks are located.  If this argument is not supplied'
  logger.info 'the script will attempt to locate a directory ci-pipeline in the current directory or in any of the current'
  logger.info "directory's parent directory.  The pipeline_name, which defaults to blank, can optionally be specified to"
  logger.info 'reference an alternative set of pipeline scripts to be used.'
  logger.info ''
  logger.info 'The following commands are supported:'
  logger.info '  info - describes each of the tasks within the pipeline and any necessary preconditions per task.'
  logger.info '  json-info - describes each of the tasks within the pipeline and any necessary preconditions per task producing a json output.'
  logger.info "  reset - resets the pipeline's state so that it can be re-run."
  logger.info '  retry - retries to run the pipeline from the previously failed task.'
  logger.info '  run - runs the pipeline.  If the pipeline previously failed then this command will itself fail.'
  logger.info '  status - shows the status of the pipeline.'
  exit 1
end
