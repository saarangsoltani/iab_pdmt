class BaseFilter
  def apply(entries)
    raise NotImplementedError, 'Subclasses must implement apply method'
  end
end
