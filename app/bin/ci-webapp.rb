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
    Dir[@home_dir + "/*"].map{ |dir| dir.split("/").last }
  end

  def projects
    Projects.new self
  end
end

class Projects
  def initialize(workspace)
    @workspace = workspace
  end

  def all
    @workspace.project_names.map { |name| Project.new name }
  end

  def project(name)
    Project.new name
  end
end

class Project
  def initialize(name)
    @name = name
  end

  def to_map
    {:id => @name, :name => @name}
  end

  def to_s
    @name
  end

  def pipelines
    Dir
  end
end

class Pipeline

end

workspace = Workspace.new File.join (File.dirname(__FILE__) + "/../../workspace")

get '/' do
  File.read(File.join(File.dirname(__FILE__), '/../data', 'index.html'))
end

get '/api/projects' do
  content_type :json

  workspace.projects.all.map { |x| x.to_map }.to_json
end

get '/api/projects/:name' do
  content_type :json

  workspace.project(params[:name]).to_map.to_json
end

