namespace :tools do
  desc "shift table sequences"
  task shift_table_sequences: :environment do
    [ "types", "statuses", "people", "members", "groups", "invitees", "events", "holidays", "comments", "teams" ].each do |table|
      result = ActiveRecord::Base.connection.exec_query("select max(id) n from #{table}")
      result.each do |row|
        n = row["n"].to_i
        n += 1
        result = ActiveRecord::Base.connection.execute("alter sequence #{table}_id_seq restart with #{n}")
        puts "Table #{table} => sequence restarted with #{n}"
      end
    end
  end
end
