require 'singleton'
require 'fileutils'

class Dx < Object
  include Singleton
  attr_accessor :client, :domain, :entry_host, :bucket, :use_test_headers

  def initialize(args = {})
    self.configure
  end

  def ingest_file(file_path, bit_file, opts = {})
    opts[:retries] ||= 5
    content = File.open(file_path, 'rb') { |f| f.read }
    self.client.post(file_url(bit_file), content, ingest_headers(bit_file, file_path, opts[:path]))
    Rails.logger.info "DX Ingested #{bit_file.name}"
  rescue Exception => e
    Rails.logger.error "Error DX Ingesting #{bit_file.name}: #{e}"
    if opts[:retries] == 0
      Rails.logger.error "Aborting."
      raise e
    else
      Rails.logger.info "Retrying."
      ingest_file(file_path, bit_file, opts.merge(:retries => opts[:retries] - 1))
    end
  end

  def delete_file(bit_file, retries = 5)
    begin
      Rails.logger.info("Trying to delete #{file_url(bit_file)} with #{delete_headers(bit_file)}")
      response = self.client.delete(file_url(bit_file), {}, delete_headers(bit_file))
      Rails.logger.info("DX Deleted #{bit_file.name}. HTTP Code: #{response.code}")
    rescue Mechanize::ResponseCodeError => e
      if e.response_code.to_i == 403 or e.response_code.to_i == 404
        Rails.logger.info "#{bit_file.name} already deleted from DX."
      else
        raise e
      end
    end
  rescue Exception => e
    Rails.logger.error "Error DX Deleting #{bit_file.name}: #{e}"
    if retries == 0
      Rails.logger.error "Aborting."
      raise e
    else
      Rails.logger.info "Retrying."
      delete_file(bit_file, retries - 1)
    end
  end

  def export_file(bit_file, target_directory, retries = 5)
    response = self.client.get(file_url(bit_file), [], nil, export_headers(bit_file))
    filename = File.join(target_directory, bit_file.name)
    File.open(filename, 'wb') do |f|
      f.write response.body
      begin
        atime = Time.parse(response.header['x-bit-meta-atime'])
        mtime = Time.parse(response.header['x-bit-meta-mtime'])
        File.utime(atime, mtime, bit_file.name)
      rescue Exception => e
        Rails.logger.error "Problem resetting atime and mtime for #{filename}. Skipping"
      end
    end
    Rails.logger.info("DX exported file: #{bit_file.name}")
  rescue Exception => e
    Rails.logger.error "Error DX exporting #{bit_file.name}: #{e}"
    if retries == 0
      Rails.logger.error 'Aborting.'
      raise e
    else
      Rails.logger.info "Retrying."
      export_file(bit_file, target_directory, retries - 1)
    end
  end

  def configure
    config = YAML.load_file(File.join(Rails.root, 'config', 'dx.yml'))[Rails.env]
    self.client = Mechanize.new.tap do |agent|
      config['hosts'].each do |host|
        agent.add_auth("http://#{host}", config['user'], config['password'])
      end
      logfile = File.join(Rails.root, 'log', 'mech.log')
      FileUtils.touch(logfile)
      agent.log = Logger.new(logfile)
      agent.redirects_preserve_verb = true
    end
    self.domain = config['domain']
    self.entry_host = config['entry_host']
    self.bucket = config['bucket']
    self.use_test_headers = config['use_test_headers'] || false
  end

  def file_url(bit_file)
    "http://#{self.entry_host}/#{self.bucket}/#{bit_file.dx_name}"
  end

  def ingest_headers(bit_file, file_path, path_from_root)
    Hash.new.tap do |headers|
      headers['Host'] = self.domain if self.domain
      headers['Content-Type'] = bit_file.content_type || 'application/octet-stream'
      headers['Content-MD5'] = bit_file.md5sum if bit_file.md5sum
      headers['x-bit-meta-atime'] = File.atime(file_path).to_s
      headers['x-bit-meta-ctime'] = File.ctime(file_path).to_s
      headers['x-bit-meta-mtime'] = File.mtime(file_path).to_s
      headers['x-bit-meta-path'] = File.join(path_from_root, bit_file.name)
      if self.use_test_headers
        #set lifepoint to assure that content gets deleted after 2 weeks even if we don't clean it up manually
        headers['Lifepoint'] = ["[#{(Time.now + 2.weeks).httpdate}] reps=2, deletable=yes",
                                "[] delete"]
      else
        headers['Lifepoint'] = "[] reps=3, deletable=yes"
      end
    end
  end

  def delete_headers(bit_file)
    Hash.new.tap do |headers|
      headers['Host'] = self.domain if self.domain
    end
  end

  def export_headers(bit_file)
    Hash.new.tap do |headers|
      headers['Host'] = self.domain if self.domain
    end
  end

end