#!/usr/bin/ruby

require 'rubygems'
require 'sinatra'
require 'json'

# require_relative 'bbb'

set :public_folder, File.dirname(__FILE__) + '/../data'
set :bind, '0.0.0.0'

get '/' do
	  File.read(File.join(File.dirname(__FILE__), '/../data', 'index.html'))
end

get '/api/projects' do
	content_type :json

	projects = Projects.new File.join(File.dirname(__FILE__), "/../../workspace")

	projects.all.map{|x| x.to_map}.to_json
end

class Projects
	def initialize(home_dir)
		@home_dir = home_dir
	end

	def all
		Dir[@home_dir + "/*"].map { |t| Project.new t.split("/").last }
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
end
