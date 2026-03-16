require "json"
require "jwt"
require "net/http"
require "openssl"
require "uri"

def get(url, token)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  req["Authorization"] = "Bearer #{token}"
  req["Content-Type"] = "application/json"
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
end

key_path = ENV.fetch("APP_STORE_CONNECT_API_KEY_PATH")
issuer_id = ENV.fetch("APP_STORE_CONNECT_ISSUER_ID")
key_id = ENV.fetch("APP_STORE_CONNECT_KEY_ID")
bundle_id = ENV.fetch("APP_IDENTIFIER", "com.GA.QuitERGY")
version_string = ENV.fetch("APP_VERSION", "1.0")

key = OpenSSL::PKey::EC.new(File.read(key_path))
token = JWT.encode(
  { iss: issuer_id, aud: "appstoreconnect-v1", exp: Time.now.to_i + 1200 },
  key,
  "ES256",
  { kid: key_id, typ: "JWT" }
)

apps = JSON.parse(get("https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]=#{bundle_id}", token).body)
app_id = apps.dig("data", 0, "id")
abort("app_not_found") unless app_id

versions = JSON.parse(get("https://api.appstoreconnect.apple.com/v1/appStoreVersions?filter[app]=#{app_id}&filter[platform]=IOS", token).body)
version_data = versions.fetch("data", [])
if version_data.empty?
  related = JSON.parse(get("https://api.appstoreconnect.apple.com/v1/apps/#{app_id}/appStoreVersions", token).body)
  version_data = related.fetch("data", [])
end
abort("version_not_found") if version_data.empty?

version_data.each do |version|
  next unless version.dig("attributes", "platform") == "IOS"
  if version_string && !version_string.empty?
    next unless version.dig("attributes", "versionString") == version_string
  end

  version_id = version["id"]
  puts "version_id=#{version_id} version=#{version.dig("attributes", "versionString")} state=#{version.dig("attributes", "appStoreState")}"

  locs = JSON.parse(get("https://api.appstoreconnect.apple.com/v1/appStoreVersions/#{version_id}/appStoreVersionLocalizations", token).body)
  loc_data = locs.fetch("data", [])
  puts "localizations=#{loc_data.size}"

  loc_data.each do |loc|
    loc_id = loc["id"]
    locale = loc.dig("attributes", "locale")
    puts "locale=#{locale}"

    sets = JSON.parse(get("https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/#{loc_id}/appScreenshotSets", token).body)
    if sets.fetch("data", []).empty?
      puts "  screenshot_sets=0"
    end
    sets.fetch("data", []).each do |set|
      set_id = set["id"]
      display_type = set.dig("attributes", "screenshotDisplayType")
      shots = JSON.parse(get("https://api.appstoreconnect.apple.com/v1/appScreenshotSets/#{set_id}/appScreenshots", token).body)
      puts "  #{display_type}: #{shots.fetch("data", []).size}"
      shots.fetch("data", []).each do |shot|
        attrs = shot.fetch("attributes", {})
        puts "    file_size=#{attrs["fileSize"]} checksum=#{attrs["sourceFileChecksum"]}"
      end
    end
  end
end
