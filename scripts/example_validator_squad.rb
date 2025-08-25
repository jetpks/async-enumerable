#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/async/enumerable"
require "resolv"

class EmailValidator
  include Async::Enumerable
  def_async_enumerable :@checks
  
  def initialize(email)
    @email = email
    @domain = email.split("@").last
    @checks = [
      -> { check_dns_record },      
      -> { check_disposable_domain }, 
      -> { check_smtp_verify },      
      -> { check_reputation }        
    ]
  end
  
  def check_dns_record
    puts "  Checking DNS record..."
    sleep(0.5)  # Simulate DNS lookup
    begin
      Resolv::DNS.open { |dns| dns.getresources(@domain, Resolv::DNS::Resource::IN::MX) }
      puts "    ✓ DNS record found"
      true
    rescue
      puts "    ✗ No DNS record"
      false
    end
  end
  
  def check_disposable_domain
    puts "  Checking if disposable domain..."
    sleep(0.3)  # Simulate API call
    disposable = ["tempmail.com", "guerrillamail.com", "10minutemail.com"]
    is_disposable = disposable.include?(@domain)
    puts "    #{is_disposable ? '✗ Disposable domain!' : '✓ Not disposable'}"
    !is_disposable
  end
  
  def check_smtp_verify
    puts "  Verifying SMTP..."
    sleep(1.0)  # Simulate SMTP check
    # For demo, just return true for known domains
    valid = ["gmail.com", "yahoo.com", "outlook.com"].include?(@domain)
    puts "    #{valid ? '✓ SMTP verified' : '✗ SMTP failed'}"
    valid
  end
  
  def check_reputation
    puts "  Checking domain reputation..."
    sleep(0.4)  # Simulate reputation check
    puts "    ✓ Good reputation"
    true
  end
  
  def valid?
    puts "\nRunning all validation checks in parallel:"
    start = Time.now
    result = @checks.async.all? { |check| check.call }
    puts "Total time: #{(Time.now - start).round(2)}s (vs ~2.2s sequential)"
    result
  end
  
  def suspicious?
    puts "\nChecking if email is suspicious (stops at first failure):"
    start = Time.now
    result = @checks.async.any? { |check| !check.call }
    puts "Total time: #{(Time.now - start).round(2)}s"
    result
  end
end

puts "Email Validator Example"
puts "=" * 40

# Test with a valid email
puts "\nValidating: user@gmail.com"
validator = EmailValidator.new("user@gmail.com")
if validator.valid?
  puts "✅ Email is valid!"
else
  puts "❌ Email is invalid"
end

puts "\n" + "-" * 40

# Test with a disposable email
puts "\nValidating: test@tempmail.com"
validator = EmailValidator.new("test@tempmail.com")
if validator.suspicious?
  puts "⚠️  Email is suspicious (stopped early!)"
else
  puts "✅ Email looks good"
end