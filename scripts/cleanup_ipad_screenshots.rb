require "json"
require "jwt"
require "net/http"
require "openssl"
require "uri"

def request(method, url, token, body: nil)
  uri = URI(url)
  klass = case method
          when :get then Net::HTTP::Get
          when :delete then Net::HTTP::Delete
          else raise "unsupported_method"
          end
  req = klass.new(uri)
  req["Authorization"] = "Bearer #{token}"
  req["Content-Type"] = "application/json"
  req.body = body if body
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
end

key_path = ENV.fetch("APP_STORE_CONNECT_API_KEY_PATH")
issuer_id = ENV.fetch("APP_STORE_CONNECT_ISSUER_ID")
key_id = ENV.fetch("APP_STORE_CONNECT_KEY_ID")
bundle_id = ENV.fetch("APP_IDENTIFIER", "com.GA.QuitERGY")
version_string = ENV.fetch("APP_VERSION", "1.0")
target_locale = ENV.fetch("APP_LOCALE", "en-US")
target_display = ENV.fetch("APP_DISPLAY_TYPE", "APP_IPAD_PRO_3GEN_129")
keep_checksums = ENV.fetch(
  "KEEP_CHECKSUMS",
  "25d10a812f5df8388f7ebb4658ce20f7,3c36e71427912fe15f30371f7eb3c20f,36c4610b270c23b13fee77523c1c0fd4"
).split(",").map(&:strip).reject(&:empty?)

key = OpenSSL::PKey::EC.new(File.read(key_path))
token = JWT.encode(
  { iss: issuer_id, aud: "appstoreconnect-v1", exp: Time.now.to_i + 1200 },
  key,
  "ES256",
  { kid: key_id, typ: "JWT" }
)

apps = JSON.parse(request(:get, "https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]=#{bundle_id}", token).body)
app_id = apps.dig("data", 0, "id")
abort("app_not_found") unless app_id

versions = JSON.parse(request(:get, "https://api.appstoreconnect.apple.com/v1/apps/#{app_id}/appStoreVersions", token).body)
version = versions.fetch("data", []).find { |v| v.dig("attributes", "versionString") == version_string }
abort("version_not_found") unless version
version_id = version["id"]

locs = JSON.parse(request(:get, "https://api.appstoreconnect.apple.com/v1/appStoreVersions/#{version_id}/appStoreVersionLocalizations", token).body)
loc = locs.fetch("data", []).find { |l| l.dig("attributes", "locale") == target_locale }
abort("locale_not_found") unless loc
loc_id = loc["id"]

sets = JSON.parse(request(:get, "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/#{loc_id}/appScreenshotSets", token).body)
set = sets.fetch("data", []).find { |s| s.dig("attributes", "screenshotDisplayType") == target_display }
abort("screenshot_set_not_found") unless set
set_id = set["id"]

shots = JSON.parse(request(:get, "https://api.appstoreconnect.apple.com/v1/appScreenshotSets/#{set_id}/appScreenshots", token).body)
data = shots.fetch("data", [])

to_delete = data.reject { |item| keep_checksums.include?(item.dig("attributes", "sourceFileChecksum")) }

puts "total=#{data.size} keep=#{data.size - to_delete.size} delete=#{to_delete.size}"
to_delete.each do |item|
  id = item["id"]
  checksum = item.dig("attributes", "sourceFileChecksum")
  res = request(:delete, "https://api.appstoreconnect.apple.com/v1/appScreenshots/#{id}", token)
  puts "delete id=#{id} checksum=#{checksum} status=#{res.code}"
end
