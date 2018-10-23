module CarrierWave::Uploader::Cache
  MAX_FILENAME_BYTES = 255

  attr_reader :real_original_filename

  private

  def original_filename=(filename)
    raise CarrierWave::InvalidParameter, "invalid filename" if filename =~ CarrierWave::SanitizedFile.sanitize_regexp

    @real_original_filename = filename.unicode_normalize!

    @original_filename = filename
    @original_filename.force_encoding('utf-8')
    @original_filename.encode!("UTF-16BE", "UTF-8", invalid: :replace, undef: :replace, replace: '')
    @original_filename.encode!("UTF-8")
    @original_filename.unicode_normalize!

    if(@original_filename.bytes.length > MAX_FILENAME_BYTES)
      original_file_extension = File.extname(@original_filename)
      @original_filename = @original_filename.mb_chars.limit(MAX_FILENAME_BYTES - original_file_extension.bytes.length).to_s
      @original_filename += original_file_extension
    end
    @original_filename
  end
end
