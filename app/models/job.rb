class Job < ApplicationRecord
  self.table_name = "que_jobs"

  def event_id
    args[0]
  end

  def run_at
    self[:run_at]&.in_time_zone
  end

  def self.que_running?
    processes = `ps aux | grep que`.split("\n").reject { |line| line =~ /grep/ }
    return false if processes.size == 0
    true
  end

  def self.que_process_id
    processes = `ps aux | grep que`.split("\n").reject { |line| line =~ /grep/ }
    puts "Processes: #{processes}"
    return nil if processes.size == 0
    processes[0].split(/\s+/)[1].to_i
  end

  def self.que_stop
    if service_exists?
      puts "service seems to exist"
      `sudo systemctl stop que.service 2> /dev/null`
    else
      pid = que_process_id
      return if pid.nil? || pid == 0
      puts "PID: #{pid}"
      Process.kill("SIGKILL", pid)
    end
  end

  def self.que_start
    if service_exists?
      puts "service seems to exist"
      `sudo systemctl start que.service 2> /dev/null`
    else
      system("bundle exec que &")
    end
  end

  def self.service_exists?(service_name = "que")
    return false unless system("command -v systemctl > /dev/null")

    # Execute the systemctl command to list service unit files and check if the given service exists
    output = `systemctl list-unit-files --type=service | grep -w #{service_name}.service`

    puts "Output: #{output}"

    # If the output is empty, the service does not exist; otherwise, it does exist
    !output.empty?
  end
end
