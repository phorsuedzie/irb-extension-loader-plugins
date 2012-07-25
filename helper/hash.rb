irb_helper.class_eval do
  def deep_merge!(into, from)
    from.each do |(key, value)|
      if into.key?(key) && hash?(into[key]) && hash?(value)
        deep_merge!(into[key], value)
      else
        # overwrite (with nil, type mismatch, don't join arrays ...)
        into[key] = value
      end
    end
    into
  end
end
