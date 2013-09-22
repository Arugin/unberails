class ArticleArea
  include Mongoid::Document
  field :title, type: Symbol

  scope :without_news, not_in({:title => :NEWS})

  has_many :articles, dependent: :restrict

  def self.default_id
    where(:title => :NO_AREA).first._id
  end
end
