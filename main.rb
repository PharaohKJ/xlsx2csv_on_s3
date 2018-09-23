# coding: utf-8

require 'aws-sdk-s3'
require 'rubyXL'
require 'logger'
require 'fileutils'
require 'json'

logger = Logger.new(STDOUT)

ERRCODE_TARGET_NOTFOUND = 1
ERRCODE_INVALID_FNAME   = 2
ERRCODE_COPY_FAILED     = 3
CSV_EXT = '.csv'.freeze
META_EXT = '.json'.freeze

target = ENV['TARGET_S3KEY']
if target.nil?
  logger.fatal 'Target Environment is not set.'
  return 1
end

fname = target.to_s.split('/').last
if fname.nil?
  logger.fatal "invalid target(#{target})"
  return 2
end

tmp_path = ENV['TMP_PATH'] || '/tmp'
tmp_csv_path = File.join(tmp_path, fname) + CSV_EXT
tmp_xls_path = File.join(tmp_path, fname)
tmp_meta_path = File.join(tmp_path, fname) + META_EXT

logger.level = ENV['LOG_LEVEL'] || 'DEBUG'

begin
  if ENV['OFFLINE_MODE'].nil?
    # 認証はENVの定数が自動的に用いられる
    s3 = Aws::S3::Client.new
    logger.info("fetch s3object #{target} on #{ENV['AWS_BUCKET']}")
    s3obj = s3.get_object(
      bucket: ENV['AWS_BUCKET'],
      key:    target
    )
    File.open(tmp_xls_path, 'wb') { |f| f.write(s3obj.body.read) }
  else
    FileUtils.cp target, tmp_xls_path
  end
rescue => e
  logger.fatal "File copy failed. #{e}"
  return ERRCODE_COPY_FAILED
end

logger.info "try to parse #{tmp_xls_path}"
book = RubyXL::Parser.parse(tmp_xls_path)
logger.info "opened #{tmp_xls_path}"

row_count = 0
line_count = 0

File.open(tmp_csv_path, 'wb') do |f|
  logger.info "convert to #{tmp_csv_path}"
  book.each do |sheet|
    sheet.each do |row|
      next unless row
      row_count = [row_count, row.cells.count].max
      record = row.cells.each_with_object([]) do |cell, obj|
        obj.push((cell && cell.value).to_s)
      end
      f.write(record.join(','))
      f.write("\n")
      line_count += 1
    end
    break # support 1st page only
  end
end

# Save to Meta Information
meta = {
  row_count: row_count,
  line_count: line_count,
  xls_file_size: File.size(tmp_xls_path),
  csv_file_size: File.size(tmp_csv_path)
}
File.open(tmp_meta_path, 'w') do |f|
  logger.info "save to #{tmp_meta_path}"
  f.write(meta.to_json)
end

# Store to S3

return unless ENV['OFFLINE_MODE'].nil?

store_csv_path = target + CSV_EXT
store_meta_path = target + META_EXT

logger.info "write s3obj to #{store_csv_path}"
s3.put_object(
  bucket: ENV['AWS_BUCKET'],
  key:    store_csv_path,
  body:   File.open(tmp_csv_path)
)

logger.info "write s3obj to #{store_meta_path}"
s3.put_object(
  bucket: ENV['AWS_BUCKET'],
  key:    store_meta_path,
  body:   File.open(tmp_meta_path)
)

return
