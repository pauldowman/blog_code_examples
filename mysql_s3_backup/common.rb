require "config"
require "rubygems"
require "aws/s3"
require "fileutils"

def run(command)
  result = system(command)
  raise("error, process exited with status #{$?.exitstatus}") unless result
end

def execute_sql(sql)
  cmd = %{mysql -u#{@mysql_user} -e "#{sql}"}
  cmd += " -p'#{@mysql_password}' " unless @mysql_password.nil?
  run cmd
end

AWS::S3::Base.establish_connection!(:access_key_id => @aws_access_key_id, :secret_access_key => @aws_secret_access_key, :use_ssl => true)

# It doesn't hurt to try to create a bucket that already exists
AWS::S3::Bucket.create(@s3_bucket)
