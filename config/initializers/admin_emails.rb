ADMIN_EMAILS = ENV.fetch("ADMIN_EMAILS", "").split(",").map(&:strip).reject(&:empty?)
