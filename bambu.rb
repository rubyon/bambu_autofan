#!/usr/bin/env ruby

require "mqtt"
require "openssl"
require "json"
require "dirigera"

$stdout.sync = true
$stderr.sync = true

PRINTER_IP = ENV["PRINTER_IP"]
ACCESS_CODE = ENV["ACCESS_CODE"]
SERIAL = ENV["SERIAL"]
USERNAME = "bblp"
PORT = 8883
DEBOUNCE = ENV["DEBOUNCE"].to_i
DIRIGERA_IP = ENV["DIRIGERA_IP"]
DIRIGERA_TOKEN = ENV["DIRIGERA_TOKEN"]
OUTLET_NAME = ENV["OUTLET_NAME"]

client = Dirigera::Client.new(DIRIGERA_IP, DIRIGERA_TOKEN)
outlet = client.outlets.find do |o|
  o.instance_variable_get(:@data)["attributes"]["customName"].strip == OUTLET_NAME.strip
end
abort("OUTLET 을 찾을 수 없습니다. (OUTLET_NAME=#{OUTLET_NAME.strip})") unless outlet

puts "OUTLET ID: #{outlet.instance_variable_get(:@data)['id']}"

ssl_context = OpenSSL::SSL::SSLContext.new
ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

is_start = false

loop do
  mqtt = nil
  begin
    mqtt = MQTT::Client.connect(
      host: PRINTER_IP,
      port: PORT,
      username: USERNAME,
      password: ACCESS_CODE,
      ssl: ssl_context
    )

    report_topic = "device/#{SERIAL}/report"

    mqtt.subscribe(report_topic)

    last_nonzero_since = nil
    last_zero_since = nil

    mqtt.get do |_topic, message|
      data = JSON.parse(message) rescue nil
      next unless data

      air_duct_state = data.dig("print", "device", "airduct", "parts")
                         &.find { |p| p["id"] == 48 }
                         &.dig("state").to_i

      puts "air_duct_state: #{air_duct_state}"

      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      if air_duct_state > 0
        last_nonzero_since ||= now
        last_zero_since = nil

        # DEBOUNCE 초 이상 지속되면 ON (이미 켜져 있지 않을 때만)
        if !is_start && (now - last_nonzero_since) >= DEBOUNCE
          puts "환기팬 ON (지속 #{DEBOUNCE}초 조건 충족)"
          outlet.on
          is_start = true
          last_nonzero_since = nil
        end
      else
        last_zero_since ||= now
        last_nonzero_since = nil

        # DEBOUNCE 초 이상 지속되면 OFF (이미 꺼져 있지 않을 때만)
        if is_start && (now - last_zero_since) >= DEBOUNCE
          puts "환기팬 OFF (지속 #{DEBOUNCE}초 조건 충족)"
          outlet.off
          is_start = false
          last_zero_since = nil
        end
      end
    end

  rescue => e
    warn "오류 발생: #{e.class} - #{e.message}"
    puts "5초 후 재접속합니다"

  ensure
    begin
      mqtt&.disconnect
    rescue => e
      warn "연결 종료 중 오류: #{e.class} - #{e.message}"
    end
  end

  sleep 5
end
