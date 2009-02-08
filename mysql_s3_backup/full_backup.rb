#!/usr/bin/env ruby

require "common"

begin
  FileUtils.mkdir_p @temp_dir

  # assumes the bucket's empty
  dump_file = "#{@temp_dir}/dump.sql.gz"
  
  cmd = "mysqldump --quick --single-transaction --create-options -u#{@mysql_user}  --flush-logs --master-data=2 --delete-master-logs"
  cmd += " -p'#{@mysql_password}'" unless @mysql_password.nil?
  cmd += " #{@mysql_database} | gzip > #{dump_file}"
  run(cmd)
  
  AWS::S3::S3Object.store(File.basename(dump_file), open(dump_file), @s3_bucket)
ensure
  FileUtils.rm_rf(@temp_dir)
end
