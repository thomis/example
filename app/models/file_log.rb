class FileLog
  attr_reader :stamp, :level, :pid, :message

  def initialize(args = {})
    @stamp = args[:stamp]
    @level = args[:level]
    @pid = args[:pid]
    @message = args[:message]
  end

  def self.parse_from_file(filename)
    logs = []
    content = File.read(filename).lines.last(5000)

    content.each do |line|
      line.strip!
      next if line[0] == "#"
      next if line.size == 0

      mg = /\[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+(INFO|WARN|ERROR)\s+(\d+)\]\s+(.+)/.match(line)
      next if mg.nil?

      logs.unshift(
        FileLog.new(
          stamp: mg[1],
          level: mg[2],
          pid: mg[3],
          message: mg[4]
        )
      )
    end
    logs
  rescue => e
    logs << FileLog.new(stamp: Time.now.strftime("%Y-%m-%d %H:%M:%S"), level: "WARN", pid: 0, message: "Exception while reading [#{filename}]: #{e}")
    logs
  end
end
