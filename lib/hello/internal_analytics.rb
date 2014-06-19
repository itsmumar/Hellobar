module Hello
  class InternalAnalytics
    class << self
      # Processes any unprocessed props and events
      def process
        cxn = ActiveRecord::Base.connection
        # Get the metadata
        last_updated_at, last_event_processed, last_prop_processed, last_visitor_user_id_processed = *(cxn.execute("SELECT * FROM `internal_processing`")).first
        internal_processing_metadata_set = false
        if last_updated_at
          internal_processing_metadata_set = true
        end

        # Process the events and props
        last_visitor_user_id_processed = process_visitor_user_ids(last_visitor_user_id_processed)
        last_event_processed = process_events(last_event_processed)
        last_prop_processed = process_props(last_prop_processed)
        last_updated_at = Time.now.to_i

        # Update the metadata
        if internal_processing_metadata_set
          cxn.execute("UPDATE `internal_processing` SET last_event_processed = #{last_event_processed}, last_prop_processed = #{last_prop_processed}, last_updated_at = #{last_updated_at}, last_visitor_user_id_processed = #{last_visitor_user_id_processed}")
        else
          cxn.execute("INSERT INTO `internal_processing` VALUES(#{last_updated_at}, #{last_event_processed}, #{last_prop_processed}, #{last_visitor_user_id_processed})")
        end
      end

      def get_person(target_type, target_id)
        # First see if we have the person in the DB already
        unless person = InternalPerson.where(:"#{target_type}_id"=>target_id).first
          # Nope - so create them
          person = InternalPerson.new
          case target_type
          when "visitor"
            person.visitor_id = target_id
          when "user"
            person.user_id = target_id.to_i
          end
        end
        return person if person
      end

      def merge_people(person1, person2)
        person = InternalPerson.new
        person.visitor_id = person1.visitor_id || person2.visitor_id
        person.user_id = person1.user_id || person2.user_id
        # Use whichever timestamp is greater
        [:first_visited_at, :signed_up_at, :completed_registration_at, :created_first_bar_at, :created_second_bar_at, :received_data_at].each do |timestamp|
          person.send("#{timestamp}=".to_sym, [person2.send(timestamp), person1.send(timestamp)].compact.max)
        end
        # Update attributes
        cxn = ActiveRecord::Base.connection
        person1_id = person1.id
        person2_id = person2.id
        person1.destroy
        person2.destroy
        person.save

        dimensions = {}
        to_delete = []
        # Load up all the dimensions for both exsting users
        cxn.execute("SELECT person_id, name, value, timestamp FROM `internal_dimensions` WHERE person_id = #{person1_id} OR person_id = #{person2_id}").each do |row|
          data = {person_id: row[0], name: row[1], value: row[2], timestamp: row[3]}
          # Only keep one dimension (whichever is later) 
          if existing = dimensions[data[:name]]
            if data[:timestamp] > existing[:timestamp]
              to_delete << existing
              dimensions[data[:name]] = data
            else
              to_delete << data
            end
          else
            # Just one so far
            dimensions[data[:name]] = data
          end
        end
        # Update the person of the ones we are keeping
        dimensions.values.each do |row|
          cxn.execute("UPDATE `internal_dimensions` SET person_id=#{person.id} WHERE person_id = #{row[:person_id]} and name = #{cxn.quote(row[:name])}")
        end
        # Delete the ones we are not keeping
        to_delete.each do |row|
          cxn.execute("DELETE FROM `internal_dimensions` WHERE person_id = #{row[:person_id]} and name = #{cxn.quote(row[:name])}")
        end

        return person
      end

      def process_visitor_user_ids(last_visitor_user_id_processed)
        cxn = ActiveRecord::Base.connection
        cxn.execute("SELECT * FROM `internal_props` WHERE `name` = 'user_id' AND id > #{last_visitor_user_id_processed || 0}").each do |row|
          id, timestamp, target_type, target_id, name, value = *row 
          person_by_visitor = get_person(target_type, target_id)
          person_by_user = get_person("user", value.to_i)

          method = nil
          if person_by_visitor.new_record? and !person_by_user.new_record?
            # The person by user already exists and we just need to update
            # the visitor id
            method = :set_visitor_id
            person = person_by_user
          elsif !person_by_visitor.new_record? and person_by_user.new_record?
            # The person by visitor already exists we just need to update
            # the user id
            method = :set_user_id
            person = person_by_visitor
          elsif !person_by_visitor.new_record? and !person_by_user.new_record?
            # They both exist, if they are not the same person we merge them
            if person_by_visitor.id != person_by_user.id
              person = merge_people(person_by_visitor, person_by_user)
            else
              # They are the same person - no need to set anything
              person = person_by_visitor
            end
          elsif person_by_visitor.new_record? and person_by_user.new_record?
            # They are both new records, so lets use the person_by_visitor
            person = person_by_visitor
            method = :set_user_id
          end

          case method
          when :set_visitor_id
            person.visitor_id = target_id unless person.visitor_id
          when :set_user_id
            person.user_id = value.to_i
          end
          
          # Update the first visited at if needed
          person.first_visited_at = timestamp if !person.first_visited_at or timestamp < person.first_visited_at
          # Save any changes
          person.save if person.changed?

          last_visitor_user_id_processed = id
        end

        return last_visitor_user_id_processed
      end

      def process_events(last_event_processed)
        cxn = ActiveRecord::Base.connection
        valid_events = ["Signed Up", "Created First Bar", "Created Second Bar", "Completed Registration", "Received Data"]
        cxn.execute("SELECT * FROM `internal_events` WHERE `name` IN (#{valid_events.collect{|e| cxn.quote(e)}.join(", ")}) AND id > #{last_event_processed || 0}").each do |row|
          id, timestamp, target_type, target_id, name = *row 
          person = get_person(target_type, target_id)
          person.first_visited_at = timestamp if !person.first_visited_at or timestamp < person.first_visited_at
          case name
            when "Signed Up"
              person.signed_up_at ||= timestamp
            when "Created First Bar"
              person.created_first_bar_at ||= timestamp
            when "Created Second Bar"
              person.created_second_bar_at ||= timestamp
            when "Completed Registration"
              person.completed_registration_at ||= timestamp
            when "Received Data"
              person.received_data_at ||= timestamp
          end
          if person.changed?
            person.save
          end
          last_event_processed = id
        end
        return last_event_processed
      end

      def process_props(last_prop_processed)
        cxn = ActiveRecord::Base.connection
        invalid_props = ["user_id"]
        cxn.execute("SELECT * FROM `internal_props` WHERE `name` NOT IN (#{invalid_props.collect{|e| cxn.quote(e)}.join(", ")}) AND id > #{last_prop_processed || 0}").each do |row|
          id, timestamp, target_type, name, value, target_id = *row
          person = get_person(target_type, target_id)
          person.first_visited_at = timestamp if !person.first_visited_at or timestamp < person.first_visited_at
          if person.changed?
            person.save
          end

          # See if we can find the internal dimension and create it
          # if we can't find it
          attributes = {:person_id=>person.id, :name=>name}
          dimension = InternalDimension.where(attributes).first || InternalDimension.new(attributes)
          # See if we have different value then what was established
          if value != dimension.value and (!dimension.timestamp || timestamp > dimension.timestamp)
            # Update it
            dimension.value = value
            dimension.timestamp = timestamp
            # Need to write your own save code because we 
            # are using a primary composite key
            if dimension.new_record?
              cxn.execute("INSERT INTO `internal_dimensions` VALUES(#{dimension.person_id}, #{cxn.quote(dimension.name)}, #{cxn.quote(dimension.value)}, #{dimension.timestamp})")
            else  
              cxn.execute("UPDATE `internal_dimensions` SET value = #{cxn.quote(dimension.value)}, timestamp = #{dimension.timestamp} WHERE person_id = #{dimension.person_id} AND name = #{cxn.quote(dimension.name)}")
            end
          end
          last_prop_processed = id
        end
        return last_prop_processed
      end
    end
  end
end
