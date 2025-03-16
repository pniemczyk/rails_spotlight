# frozen_string_literal: true

module RailsSpotlight
  class Storage
    attr_reader :key

    def initialize(key)
      @key = key
    end

    def write(value)
      FileUtils.mkdir_p dir_path
      # Use File.binwrite instead File.open(json_file, 'wb') { |file| file.write(value) }
      File.binwrite(json_file, value)
      maintain_file_pool(RailsSpotlight.config.storage_pool_size)
    end

    def read = File.exist?(json_file) ? File.read(json_file) : '[]'

    private

    def maintain_file_pool(size)
      files = Dir["#{dir_path}/*.json"]
      files = files.sort_by { |f| -file_ctime(f) }
      (files[size..] || []).each { |file| FileUtils.rm_f(file) }
    end

    def file_ctime(file)
      File.stat(file).ctime.to_i
    rescue Errno::ENOENT
      0
    end

    def json_file = @json_file ||= File.join(dir_path, "#{key}.json")
    def dir_path = @dir_path ||= RailsSpotlight.config.storage_path
  end
end
