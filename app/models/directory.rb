class Directory < ActiveRecord::Base
  attr_accessible :name
  acts_as_tree order: 'name'

  has_many :bit_files, :dependent => :restrict, :order => 'name', :inverse_of => :directory

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :parent_id
end
