require 'set'
class Directory < ActiveRecord::Base
  attr_accessible :name
  acts_as_tree order: 'name'

  has_many :bit_files, :dependent => :restrict, :order => 'name', :inverse_of => :directory

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :parent_id

  def bit_ingest(source_directory, opts = {})
    #find all files and directories in the source directory
    sources = (Dir[File.join(source_directory, '*')] + Dir[File.join(source_directory, '.*')].reject {|f| ['.', '..'].include?(File.basename(f))}).sort
    source_dirs = sources.select {|s| File.directory?(s)}
    source_files = sources.select {|s| File.file?(s)}
    #ingest each file in the directory
    bit_ingest_files(source_files, opts)
    #ensure subdirectories are present
    subdirs = ensure_subdirectories(source_dirs, opts)
    #recursively ingest each subdirectory
    subdirs.each {|subdir| subdir.bit_ingest(File.join(source_directory, subdir.name), opts)}
  end

  def bit_ingest_files(files, opts = {})
    #ensure file objects exist
    current_files = existing_file_names
    files.each do |file|
      name = File.basename(file)
      unless current_files.include?(name)
        self.bit_files.create(:name => name)
      end
    end
    #ingest into dx if necessary for each one
    base_path = self.path
    file_typer = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
    self.bit_files(true).each do |bit_file|
      unless bit_file.dx_ingested
        file_path = File.join(base_path, bit_file.name)
        #compute file stuff as needed. Save file.
        bit_file.md5sum = Digest::MD5.file(file_path).base64digest
        bit_file.content_type = file_typer.file(file_path)
        bit_file.dx_id = UUID.generate
        bit_file.save
        #ingest into DX
        #Dx.instance.ingest_file(file_path, bit_file)
        #mark as ingested and resave.
        #bit_file.dx_ingested = true
        #bit_file.save
      end
    end
  end

  def ensure_subdirectories(dirs, opts = {})
    current_subdirs = existing_subdirectory_names
    dirs.each do |dir|
      name = File.basename(dir)
      unless current_subdirs.include?(name)
        self.children.create(:name => name)
      end
    end
    self.children(true)
  end

  def existing_file_names
    self.bit_files.collect{|bf| bf.name}.to_set
  end

  def existing_subdirectory_names
    self.children.collect {|dir| dir.name}.to_set
  end

  def relative_path
    dirs = self.self_and_ancestors.reverse
    dirs.shift
    File.join(*(dirs.collect {|dir| dir.name}))
  end

end
