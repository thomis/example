require "yaml"

class ChangeLog
  attr_reader :date, :changes

  def initialize(args = {})
    @date = args[:date]
    @changes = args[:changes]
  end

  def self.parse_from_file(filename)
    Time.zone = "Europe/Zurich"
    YAML.load_file(filename).map { |raw|
      begin
        stamp = Time.zone.parse(raw["date"])
      rescue
        stamp = Time.now
      end

      ChangeLog.new(
        date: stamp,
        changes: raw["changes"]
      )
    }
  rescue => e
    [
      ChangeLog.new(
        date: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
        changes: [ "Exception while reading [#{filename}]: #{e}" ]
      )
    ]
  end
end
