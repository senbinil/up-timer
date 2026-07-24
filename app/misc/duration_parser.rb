class DurationParser
  SUFFIXES = {
    /^(\d+)\s*(?:seconds?|secs?|s)$/i     => 1,
    /^(\d+)\s*(?:minutes?|mins?|m)$/i     => 60,
    /^(\d+)\s*(?:hours?|hrs?|h)$/i        => 3600
  }.freeze

  # Parse a human-friendly duration string into seconds.
  # Returns the integer number of seconds, or nil if the format is invalid.
  #
  #   DurationParser.parse("30s")   # => 30
  #   DurationParser.parse("5m")    # => 300
  #   DurationParser.parse("2h")    # => 7200
  #   DurationParser.parse("6hrs")  # => 21600
  #   DurationParser.parse("90")    # => 90   (bare number → seconds)
  #   DurationParser.parse("abc")   # => nil
  def self.parse(value)
    return nil if value.blank?

    s = value.to_s.strip
    return nil if s.blank?

    # Try suffixed formats first
    SUFFIXES.each do |pattern, multiplier|
      if s.match?(pattern)
        return s.match(pattern)[1].to_i * multiplier
      end
    end

    # Fall back to bare integer (interpreted as seconds)
    return s.to_i if s.match?(/\A\d+\z/)
    nil
  end

  # Format a number of seconds into a concise human-readable string.
  #
  #   DurationParser.format(30)     # => "30 seconds"
  #   DurationParser.format(60)     # => "1 minute"
  #   DurationParser.format(300)    # => "5 minutes"
  #   DurationParser.format(3600)   # => "1 hour"
  #   DurationParser.format(7200)   # => "2 hours"
  #   DurationParser.format(3660)   # => "1 hour 1 minute"
  #   DurationParser.format(nil)    # => nil
  def self.format(seconds)
    return nil if seconds.nil?

    total = seconds.to_i
    return "0 seconds" if total <= 0

    hours   = total / 3600
    minutes = (total % 3600) / 60
    secs    = total % 60

    parts = []
    parts << "#{hours} #{hours == 1 ? "hour" : "hours"}"       if hours > 0
    parts << "#{minutes} #{minutes == 1 ? "minute" : "minutes"}" if minutes > 0
    parts << "#{secs} #{secs == 1 ? "second" : "seconds"}"      if secs > 0 && hours == 0

    parts.join(" ")
  end
end
