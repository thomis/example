require "open3"

class Import
  def initialize(stream)
    @raw_data = stream.read
  end

  def process
    json_load(JSON.parse(@raw_data))

    [ :notice, "Data have been imported" ]
  rescue => e
    AppLogger.error("Unexpected exception: #{e}\n\n#{e.backtrace}")
    [ :alert, "Unexpected exception: #{e}" ]
  end

  private

  def json_load(data)
    AppLogger.info("Import gestartet...")

    logs_part1 = []
    logs_part2 = []
    known_person_ids = []

    # restore documents
    if data["data_base64"]
      File.write(DATA_BASE64_FILE, data["data_base64"])

      # Set decoding option based on platform
      option = (RUBY_PLATFORM == "x86_64-darwin15" ? "D" : "d")

      # Safely remove files in DATA_FOLDER
      FileUtils.rm_rf(Dir.glob(File.join(DATA_FOLDER, "*")))

      error_message = nil
      return_value = nil

      Open3.popen3("base64", "-#{option}", DATA_BASE64_FILE, "|", "tar", "xzC", DATA_FOLDER) do |stdin, stdout, stderr, wait_thr|
        return_value = wait_thr.value
        error_message = [ stdout.read, stderr.read ].compact.join("; ")
      end

      if return_value.success?
        # delete tmp data file if all is fine
        system("rm -f", DATA_BASE64_FILE)
        logs_part1 << "Dokumente wurden erfolgreich importiert"
      else
        error_message = "Dokumente konnten nicht importiert werden: " + error_message
        AppLogger.error(error_message)
        raise error_message
      end
    end

    ActiveRecord::Base.transaction do
      APPLICATION_MODELS.each do |model|
        AppLogger.info("About to work on model [#{model}]...")

        next if data[model].nil?
        next if data[model].instance_of?(Array) && data[model].size == 0
        ids = []
        added = 0
        updated = 0

        data[model].each do |item_properties|
          ids << item_properties["id"]

          begin
            item = model.constantize.find(item_properties["id"])

            # do an update
            item.update!(item_properties)
            updated += 1
          rescue
            unless item_properties["creator_id"].nil?
              unless known_person_ids.include?(item_properties["creator_id"])
                item_properties["creator_id"] = 0
              end
            end

            unless item_properties["updator_id"].nil?
              unless known_person_ids.include?(item_properties["updator_id"])
                item_properties["updator_id"] = 0
              end
            end

            # create a new instance
            m = model.constantize.new(item_properties)
            added += 1 if m.save(validate: false)

            # track known person ids
            if model == "Person"
              known_person_ids << m.id
            end
          end
        end

        logs_part1 << "#{model}: Records [#{added}] added, [#{updated}] updated"

        # get max id and next sequence
        max_id = ids.max
        seq_name = "#{model.underscore.pluralize}_id_seq"
        seq_name = "que_jobs_id_seq" if model == "Job"

        next_seq = ActiveRecord::Base.connection.select_values("select nextval('#{seq_name}')")[0].to_i

        msg = "Sequence [#{seq_name}]: max_id [#{max_id}], next_seq [#{next_seq}]"

        # do we need to ajust the sequence?
        unless max_id <= next_seq
          # Ensure `max_id` is safely converted to an integer
          max_id = max_id.to_i

          # Sanitize `seq_name` to prevent SQL injection
          sanitized_seq_name = ActiveRecord::Base.connection.quote_table_name(seq_name)

          # Execute the query with a safely interpolated sequence name and parameter binding for `max_id`
          ActiveRecord::Base.connection.execute(
            ActiveRecord::Base.sanitize_sql_array(
              [ "ALTER SEQUENCE #{sanitized_seq_name} RESTART WITH ?", max_id ]
            )
          )

          next_seq = ActiveRecord::Base.connection.select_values("select nextval('#{seq_name}')")[0].to_i
          msg += ", adapted to next_seq [#{next_seq}]"
        end

        logs_part2 << msg
      end
    end

    # write logs....
    logs_part1.each do |log|
      AppLogger.info(log)
    end
    logs_part2.each do |log|
      AppLogger.info(log)
    end

    AppLogger.info("Import abgeschlossen")
  end

  def csv_load
  end
end
