#!/usr/bin/ruby

require 'rubygems'
require 'sinatra'
require 'json'

# require_relative 'bbb'

set :public_folder, File.dirname(__FILE__) + '/../data'
set :bind, '0.0.0.0'

class Workspace
  def initialize(home_dir)
    @home_dir = home_dir
  end

  def project_names
    Dir["#{@home_dir}/*"].map { |dir| dir.split('/').last }
  end

  def projects
    Projects.new self
  end

  def project(name)
    Project.new(self, name)
  end

  def pipeline_names(project_name)
    Dir["#{@home_dir}/#{project_name}/rc*"].map { |dir| dir.split('/').last }
  end

  def pipeline_home_dir(project_name, pipeline_name)
    "#{@home_dir}/#{project_name}/#{pipeline_name}"
  end
end

class Projects
  def initialize(workspace)
    @workspace = workspace
  end

  def all
    @workspace.project_names.map { |name| Project.new(@workspace, name) }
  end

  def project(name)
    Project.new(@workspace, name)
  end
end

class Project
  def initialize(workspace, name)
    @workspace = workspace
    @name = name
  end

  def name
    @name
  end

  def to_map
    {:id => @name, :name => @name}
  end

  def to_s
    @name
  end

  def pipelines
    @workspace.pipeline_names(@name).map { |name| Pipeline.new(@workspace, self, name) }
  end
end

class Pipeline
  def initialize(workspace, project, name)
    @workspace = workspace
    @project = project
    @name = name

    refresh_status
  end

  def home_dir
    @workspace.pipeline_home_dir(@project.name, @name)
  end

  def to_map
    {:project_name => @project, :name => @name}.merge(@status)
  end

  def refresh_status
    @status = JSON.parse(`#{File.dirname(__FILE__)}/ci-pipeline.rb #{home_dir}/#{@project.name} status`)
  end
end

workspace = Workspace.new File.join (File.dirname(__FILE__) + "/../../workspace")

get '/' do
  File.read(File.join(File.dirname(__FILE__), '/../data', 'index.html'))
end

get '/api/projects' do
  content_type :json

  workspace.projects.all.map do |x|
    last_pipeline = x.pipelines.last
    if last_pipeline.nil?
      x.to_map
    else
      x.to_map.merge({last_status: last_pipeline.to_map})
    end
  end.to_json
end

get '/api/projects/:name/pipelines' do
  content_type :json

  workspace.project(params[:name]).pipelines.map { |p| p.to_map }.to_json
end

get '/api/projects/:name' do
  content_type :json

  workspace.project(params[:name]).to_map.to_json
end

