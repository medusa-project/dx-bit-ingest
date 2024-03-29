class BitFile < ActiveRecord::Base
  attr_accessible :content_type, :directory_id, :dx_ingested, :dx_name, :md5sum, :name
  belongs_to :directory
  before_create :assign_uuid
  before_destroy :not_dx_ingested

  validates_presence_of :directory_id, :name
  validates_uniqueness_of :name, :scope => :directory_id
  validates_uniqueness_of :dx_name

  def assign_uuid
    self.dx_name = UUID.generate
  end

  def full_delete
    self.dx_delete(false)
    self.destroy
  end

  def dx_delete(save = true)
    Dx.instance.delete_file(self)
    self.dx_ingested = false
    self.save if save
  end

  def not_dx_ingested
    !self.dx_ingested
  end

end
