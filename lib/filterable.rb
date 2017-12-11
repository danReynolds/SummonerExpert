class Filterable
  ORDER = {
    highest: :highest,
    lowest: :lowest
  }.freeze

  ACCESSORS = [
    :list_position, :list_size, :list_order, :collection, :sort_method,
    :filtered_size, :reverse
  ].freeze
  ACCESSORS.each do |accessor|
    attr_accessor accessor
  end

  DEFAULTS = {
    list_position: 1,
    list_size: 1,
    list_order: ORDER[:desc],
    collection: [],
    # The default sort order is best = lowest values
    reverse: false
  }.freeze

  def initialize(args = {})
    args = args.with_indifferent_access
    self.class::ACCESSORS.each do |key|
      instance_variable_set("@#{key}", args[key].present? ? args[key] : DEFAULTS[key])
    end

    @list_position = @list_position.to_i
    @list_size = @list_size.to_i
  end

  def real_size
    @collection.size
  end

  def requested_size
    @list_size
  end

  # Return the filter information such as whether it was a complete filtering,
  # whether it had an offset list position, and whether no, one or multiple
  # collection items were returned
  def filter_types
    size_type = case @filtered_size
    when 0
      :empty
    when 1
      :single
    else
      :multiple
    end

    {
      size_type: size_type,
      position_type: @list_position == 1 ? :normal : :offset,
      fulfillment_type: @filtered_size == requested_size ? :complete : :incomplete
    }
  end

  # Perform the filter using the specified sorting method, list size and position
  # constraints
  def filter
    collection = @collection
    collection = collection.sort_by(&@sort_method) if @sort_method
    collection.reverse! if @list_order.to_sym == ORDER[:lowest] || @reverse
    collection = collection[((@list_position) - 1)..-1] || []

    collection.first(requested_size).tap do |filtered_collection|
      @filtered_size = filtered_collection.size
    end
  end
end
