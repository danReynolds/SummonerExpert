class Champion < Collection
  include ActiveModel::Validations
  CHAMPION_NAMES = Rails.cache.read(:champions).values.map { |data| data[:name] }
  ACCESSORS = [
    :name, :roles, :stats, :tags, :title, :passive, :spells, :allytips,
    :enemytips, :key
  ].freeze
  ACCESSORS.each do |accessor|
    attr_accessor accessor
  end

  validates :name, presence: true
  validates :name, inclusion: { in: CHAMPION_NAMES }

  def initialize(attributes = {})
    @name = attributes[:name].strip
    if data = Rails.cache.read(name: @name) || match_collection(@name, CHAMPION_NAMES)
      ACCESSORS.each do |key|
        instance_variable_set("@#{key}", data[key])
      end
    end
  end

  def find_by_role(role)
    if role.blank?
      return @roles.length == 1 ? @roles.first : nil
    end

    @roles.detect do |role_data|
      role_data[:role] == role
    end
  end

  def error_message
    errors.messages.map do |key, value|
      "#{key} #{value.first}"
    end.en.conjunction(article: false)
  end
end
