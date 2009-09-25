#!/usr/bin/env ruby

require "common"

# Retrieve a single file from S3
def retrieve_file(file)
  key = File.basename(file)
  AWS::S3::S3Object.find(key, @s3_bucket)
  
  open(file, 'w') do |f|
    AWS::S3::S3Object.stream(key, @s3_bucket) do |chunk|
      f.write chunk
    end
  end
end

# List the files matching filename_prefix in the S3 bucket
def list_keys(filename_prefix)
  AWS::S3::Bucket.objects(@s3_bucket, :prefix => filename_prefix).collect{|obj| obj.key}
end

# Retrieve the files matching filename_prefix in the S3 bucket
def retrieve_files(filename_prefix, local_dir)
  list_keys(filename_prefix).each do |k|
    file = "#{local_dir}/#{File.basename(k)}"
    retrieve_file(file)
  end      
end

begin
  FileUtils.mkdir_p @temp_dir
  
  # download the dump file from S3
  file = "#{@temp_dir}/dump.sql.gz"
  retrieve_file(file)
  
  # restore the dump file
  cmd = "gunzip -c #{file} | mysql -u#{@mysql_user} "
  cmd += " -p'#{@mysql_password}' " unless @mysql_password.nil?
  cmd += " #{@mysql_database}"
  run cmd
  
  # download the binary log files
  retrieve_files("mysql-bin.", @temp_dir)
  logs = Dir.glob("#{@temp_dir}/mysql-bin.[0-9]*").sort
  
  # restore the binary log files
  logs.each do |log|
    # The following will be executed for each binary log file
    cmd = "mysqlbinlog --database=#{@mysql_database} #{log} | mysql -u#{@mysql_user} "
    cmd += " -p'#{@mysql_password}' " unless @mysql_password.nil?
    run cmd
  end
ensure
  FileUtils.rm_rf(@temp_dir)
end
