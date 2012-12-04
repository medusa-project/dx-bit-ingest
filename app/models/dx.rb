require 'singleton'

class Dx < Object
  include Singleton
  attr_accessor :client, :domain, :entry_host, :bucket

  def initialize(args = {})
    self.configure
  end

  def ingest_file(file_path, bit_file, retries = 5)
    content = File.open(file_path, 'rb') { |f| f.read }
    self.client.post(file_url(bit_file), content, ingest_headers(bit_file))
    Rails.logger.info "DX Ingested #{bit_file.name}"
  rescue Exception => e
    Rails.logger.error "Error DX Ingesting #{bit_file.name}: #{e}"
    if retries == 0
      Rails.logger.error "Aborting."
      raise e
    else
      Rails.logger.info "Retrying."
      ingest_file(file_path, bit_file, retries - 1)
    end
  end

  def delete_file(bit_file, retries = 5)
    self.client.delete(file_url(bit_file), {}, delete_headers(bit_file))
    Rails.logger.info("DX Deleted #{bit_file.name}")
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
    File.open(File.join(target_directory, bit_file.name), 'wb') do |f|
      f.write response.body
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
    config = YAML.load_file(File.join(Rails.root, 'config', 'dx.yml'))
    self.client = Mechanize.new.tap do |agent|
      config['hosts'].each do |host|
        agent.add_auth("http://#{host}", config['user'], config['password'])
      end
    end
    self.domain = config['domain']
    self.entry_host = config['entry_host']
    self.bucket = config['bucket']
  end

  def file_url(bit_file)
    "http://#{self.entry_host}/#{self.bucket}/#{bit_file.dx_name}"
  end

  def ingest_headers(bit_file)
    Hash.new.tap do |headers|
      headers['Host'] = self.domain if self.domain
      headers['Content-Type'] = bit_file.content_type || 'application/octet-stream'
      headers['Content-MD5'] = bit_file.md5sum if bit_file.md5sum
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