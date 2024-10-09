require "date"

# GitLog class represents a git log record
class GitLog
  attr_accessor :commit, :author, :email, :date, :note

  def initialize(args = {})
    @commit = args[:commit]
    @author = args[:author]
    @email = args[:email]
    @date = args[:date].nil? ? DateTime.now : DateTime.parse(args[:date])
    @note = args[:note]
  end

  def self.parse(buffer)
    raw_logs = buffer.split("commit ")
    raw_logs.shift

    raw_logs.map do |raw_log|
      l = raw_log.split("\n")

      commit = l.shift
      _merge = l.shift if /merge/i.match?(l[0])
      author = l.shift.to_s.split("Author: ")[1]
      x = author.to_s.split(" ")
      email = x.pop.gsub(/<|>/, "")
      name = x.join(" ")

      date = l.shift.to_s.split("Date: ")[1].to_s.strip
      note = l.join("\n").strip

      GitLog.new(commit: commit, author: name, email: email, date: date, note: note)
    end
  rescue => ex
    GitLog.new(note: ex.to_s)
  end
end
