class Image < Asset
  has_attached_file :attachment, 
                    :styles => { :mini => '48x48>', :small => '100x100>', :product => '240x240>', :large => '600x600>' }, 
                    :default_style => :product,
                    :url => "/assets/products/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/assets/products/:id/:style/:basename.:extension"

  # save dimensions as height/width, to support easy finding of scaled height from various widths
  # seems this can't be called until very late, has to have files in assets/ etc
  def find_dimension
    original_file = File.join('.', 'public', attachment.url(:original).gsub(/\?\d+$/, ''))
    info = `identify #{original_file}`
    info =~ /.*?(\d+)x(\d+).*/
    $1.blank? || $2.blank? ? 1 : ($2.to_f / $1.to_f)
  end
end
