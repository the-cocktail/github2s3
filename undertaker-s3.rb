#!/usr/bin/ruby
#############################################################
# Author: Akhil Bansal (http://webonrails.com)
#############################################################

AWS_ACCESS_KEY_ID = "ACCESS_KEY"
AWS_SECRET_ACCESS_KEY = "SECRET_KEY"

# S3 bucket name to put dumps
S3_BUCKET = "github-backup"

USE_SSL = true


require 'trollop'
require 'rubygems'
require 'fileutils'
require  'aws/s3'
require 'yaml'
require "colorize"

REPOSITORY_FILE = File.dirname(__FILE__) + '/github_repos.yml'

AWS::S3::Base.establish_connection!(
    :access_key_id     => AWS_ACCESS_KEY_ID,
    :secret_access_key => AWS_SECRET_ACCESS_KEY,
    :use_ssl => USE_SSL

  )

class Bucket < AWS::S3::Bucket
end

class  S3Object < AWS::S3::S3Object
end

def  clone_and_upload_to_s3(options)
	 puts "\n\nChecking out #{options[:name]} ...".green
	 clone_command = "cd #{S3_BUCKET} && git clone --bare #{options[:clone_url]} #{options[:name]}"
   puts clone_command.yellow
   system(clone_command)
	 puts "\n Compressing #{options[:name]} ".green
	 system("cd #{S3_BUCKET} && tar czf #{compressed_filename(options[:name])} #{options[:name]}")
	 
	 upload_to_s3(compressed_filename(options[:name]))
	 
 end
 
 def compressed_filename(str)
	 str+".tar.gz"
 end	 
 
 def upload_to_s3(filename)
	 begin
		puts "** Uploading #{filename} to S3".green
		path = File.join(S3_BUCKET, filename)
		S3Object.store(filename, File.read(path), s3bucket)
	 rescue Exception => e
		puts "Could not upload #{filename} to S3".red
		puts e.message.red
	 end
 end
  
def delete_dir_and_sub_dir(dir)
  Dir.foreach(dir) do |e|
    # Don't bother with . and ..
    next if [".",".."].include? e
    fullname = dir + File::Separator + e
    if FileTest::directory?(fullname)
      delete_dir_and_sub_dir(fullname)
    else
      File.delete(fullname)
    end
  end
  Dir.delete(dir)
end

def ensure_bucket_exists
	 begin
		bucket = Bucket.find(s3bucket)
	 rescue AWS::S3::NoSuchBucket => e
		puts "Bucket '#{s3bucket}' not found."
		puts "Creating Bucket '#{s3bucket}'. "
		
		begin 
			Bucket.create(s3bucket)
			puts "Created Bucket '#{s3bucket}'. "
		rescue Exception => e
			puts e.message
		end
	 end
 
 end

def s3bucket
	s3bucket = S3_BUCKET 
end


def back_repos_from_arguments
	ARGV.each do |arg|
		begin
			name = arg.split('/').last
			clone_and_upload_to_s3(:name => name, :clone_url => arg) 
		rescue Exception => e
			puts e.message.red
		end
	end
end

def backup_repos
  back_repos_from_arguments
end

opts = Trollop::options do
  opt :n, 'dry-run', :default => false   # flag dry-run
  opt :repo, 'Clone Repository', :type => :string
  opt :bucket, 'Bucket name', :type => :string
  opt :debug, 'debug flag', :default => false
  opt :aws_access_key_id, 'AWS access key ID', :default => ENV['AWS_ACCESS_KEY_ID']
  opt :aws_secret_access_key, 'AWS secret access key', :default => ENV['AWS_SECRET_ACCESS_KEY']
end

puts "options: " if opts[:debug]
p opts if opts[:debug]

begin
	# create temp dir
	Dir.mkdir(S3_BUCKET) rescue nil
	ensure_bucket_exists
	backup_repos
ensure	
	# remove temp dir
	delete_dir_and_sub_dir(S3_BUCKET)
end

