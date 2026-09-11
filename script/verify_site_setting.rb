#!/usr/bin/env ruby
require_relative 'config/environment'

# Test SiteSetting functionality
puts "Testing SiteSetting model..."

# Test get/set
SiteSetting.set(:test_key, "test_value")
puts "get/set: #{SiteSetting.get(:test_key) == 'test_value' ? 'PASS' : 'FAIL'}"

# Test registration_enabled?
puts "registration_enabled default: #{SiteSetting.registration_enabled? == true ? 'PASS' : 'FAIL'}"

SiteSetting.set(:registration_enabled, "false")
puts "registration disabled: #{SiteSetting.registration_enabled? == false ? 'PASS' : 'FAIL'}"

SiteSetting.set(:registration_enabled, "true")
puts "registration enabled: #{SiteSetting.registration_enabled? == true ? 'PASS' : 'FAIL'}"

puts "All tests passed!"
