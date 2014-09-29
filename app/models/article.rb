#encoding: utf-8
class Article
  require 'nokogiri'
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps
  include Concerns::Searchable
  include Concerns::Ownerable
  include Concerns::Randomizable
  include Concerns::Shortable
  include Concerns::Taggable
  include Concerns::Commentable
  include Concerns::Sortable
  include Mongo::Voteable
  include Concerns::Statable
  include PublicActivity::Model

  set_initial_state Initial

  sortable_fields({title: :VIEWS, sort_by: :impressions_count})

  is_impressionable counter_cache: true, unique: :ip_address

  field :title, type: String
  field :logo, type: String
  field :content, type: String
  field :tmpContent, type: String
  field :script, type: String
  field :baseRating, type: Integer
  field :rating, type: Integer
  field :system_tag, type: Symbol
  field :to_news, type: Boolean, default: false
  field :impressions_count, type: Integer, default: 0
  field :state, type: String

  slug  :title, history: true

  belongs_to :article_area
  belongs_to :article_type
  belongs_to :cycle
  has_many :images, dependent: :destroy

  search_in :title, :tags

  validates :title, presence: true, length: {minimum: 4, maximum: 70}
  validates :tmpContent, length: {maximum: 20000}

  delegate :correct_title, to: :cycle, prefix: true, allow_nil: true

  scope :last_news, lambda { |user, params = {}|
    search_for(user,params).any_of({'$and' => [{state: 'Article::Approved'}, {to_news: true}]}, {'$and' => [{state: 'Article::Approved'}, {article_type: ArticleType.where(title: "NEWS").first}]}, {'$and' => [{state: 'Article::Changed'}, {to_news: true}]}, {'$and' => [{state: 'Article::Changed'}, {article_type: ArticleType.where(title: "NEWS").first}]}).order_by([:created_at, :desc])
  }

  scope :popular, -> {unscoped.order_by(impressions_count: :desc).limit(2)}

  scope :by_area, lambda { |user, params = {}, area|
    scope = search_for(user,params).any_of({state: 'Article::Approved'},{state: 'Article::Changed'})
    if area.present?
      scope.where(article_area: area)
    else
      scope
    end
  }

  scope :non_approved, lambda { |user, params = {}|
    search_for(user,params).where(state: 'Article::Published')
  }

  scope :approved, lambda { |user, params = {}|
    search_for(user,params).any_of({state: 'Article::Approved'},{state: 'Article::Changed'}).order_by(created_at: :desc)
  }

  scope :random, lambda {
    any_of({state: 'Article::Approved'},{state: 'Article::Changed'}).not_in(article_type: ArticleType.where(title: "NEWS").first)
  }

  scope :unprocessed, lambda { |user, params = {}|
    unscoped.search_for(user, params).not_in(state: 'Article::Approved')
  }

  voteable self, up: +1, down: -1
  voteable Cycle, up: +1, down: -1

  def tiny_content
    truncate(strip_tags(short_content), length: 200, omission: '...')
  end

  def short_content
    body = Nokogiri::HTML(content).xpath("//body")
    content = body.xpath("node()[comment()=' unbebreak ']/preceding-sibling::*")
    content.present? ? content.to_html : body.xpath("//body/node()").to_html.gsub("\n", "")
  end

  def clean_content
    return nil if content.nil?
    Nokogiri::HTML(content).xpath("//body/node()").to_html
  end

  def get_logo_url
     first_image_src || logo
  end

  def article?
    true
  end

  def article_area_id
    article_area.nil? ? ArticleArea.default_id : article_area._id
  end

  def article_type_id
    article_type.nil? ? ArticleType.default_id : article_type._id
  end

  def cycle_id
    cycle.nil? ? author.cycles.where(title: :NO_CYCLE).first._id : cycle._id
  end

  def correct_title
    truncate(title, length: 40, omission: '...')
  end

  def upload_images
    doc = content_to_doc
    doc.xpath('//img').each do |image|
      unless image_exists? image['src']
        uploaded_image = image_from_url(image['src'])
        image.set_attribute("src" , uploaded_image.file.url) if uploaded_image.present?
      end
    end
    self.content = doc.to_s
  end

  def remove_redundant_images
    self.images.each do |image|
      image.destroy if content_images.detect{|content_image| content_image['src'] == image.file.url}.nil?
    end
  end

  protected

  def content_to_doc
    Nokogiri::HTML(content)
  end

  def first_image_src
    if images.first.present?
      images.first.file.url :thumb
    else
      image = content_images.first
      image['src'] if image.present? and image['src'].index('http://').present?
    end
  end

  def content_images
    doc = content_to_doc
    doc.xpath('//img')
  end

  def image_from_url(url)
    self.images.create file: open(url)
  rescue => e
    puts "Can not upload image from #{url} to #{title}"
  end

  def image_exists?(src)
    self.images.detect {|image| puts image.file.url; image.file.url == src}.present?
  end

end
