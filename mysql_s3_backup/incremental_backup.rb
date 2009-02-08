#!/usr/bin/env ruby

require "common"

begin
  FileUtils.mkdir_p @temp_dir
  execute_sql "flush logs"
  logs = Dir.glob("#{@mysql_bin_log_dir}/mysql-bin.[0-9]*").sort
  logs_to_archive = logs[0..-2] # all logs except the last
  logs_to_archive.each do |log|
    # The following executes once for each filename in logs_to_archive
    AWS::S3::S3Object.store(File.basename(log), open(log), @s3_bucket)
  end
  execute_sql "purge master logs to '#{File.basename(logs[-1])}'"
ensure
  FileUtils.rm_rf(@temp_dir)
end
