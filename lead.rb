require "json"
require "date"
require "colorize"

class Lead
  attr_accessor :previous_version, :data

  @@all = []
  @@valid = []
  @@duplicates = []
  @@duplicates_by_email_count = 0
  @@duplicates_by_id_count = 0

  def initialize(lead)
    @data = lead
    @previous_version = {}
  end

  def self.store_lead_if_valid(lead)
    unless lead.is_duplicate?
      @@valid << lead
    end
  end

  def self.load_leads_from_file(file)
    JSON.parse(File.read(file))["leads"].each do |lead|
      self.all << self.new(lead)
    end
  end

  def self.output_summary_to_cli
    puts self.summary_msg_arr(with_colors=true).join
  end

  def self.create_valid_leads_file
    formatted_date = DateTime.now.strftime("%Y%m%d-%H:%M:%S")
    file_name = "valid-leads-#{formatted_date}.json"

    File.open(file_name, "w+") do |file|
      file.puts @@valid.to_json
    end

    puts "\nValid leads file has been generated:".blue.bold + " #{file_name}"
  end

  def self.output_change_log_file_info
    puts "\n"
    puts "See change log for more details: ".blue.bold + "change_log.txt"
    puts "\n"
  end

  def self.update_change_log
    File.open("change_log.txt", "a") do |file|
      formatted_date = DateTime.now.strftime("%Y%m%d-%H:%M:%S")
      file.puts "[LOG_ENTRY: #{formatted_date}] ".ljust(85, "-")
      file.puts "\n"

      @@valid.each do |lead|
        unless lead.previous_version.empty?
          previous_version = lead.previous_version[:lead]

          file.puts "[LEAD UPDATED]\n".ljust(100, "-")

          if lead.previous_version[:duplicate_email_found]
            file.puts "DUPLICATE EMAIL FOUND: #{previous_version.email}"
          end

          if lead.previous_version[:duplicate_id_found]
            file.puts "DUPLICATE ID FOUND: #{previous_version.id}"
          end

          file.puts "\n"
          file.puts "[DUPLICATE LEAD]:"
          file.puts JSON.pretty_generate(previous_version.data)
          file.puts "\n"
          file.puts "[UPDATED LEAD]:"
          file.puts JSON.pretty_generate(lead.data)
          file.puts "\n"
          file.puts "[FIELD CHANGES]"

          previous_version.data.keys.each do |key|
            new_val = lead.data[key]
            old_val = previous_version.data[key]

            if new_val != old_val
              file.puts "#{key.capitalize} field changed from \"#{old_val}\" to \"#{new_val}\""
            end
          end

          file.puts "\n"
        end
      end

      file.puts self.summary_msg_arr.join
    end
  end

  def self.all
    @@all
  end

  def self.clear_all
    @@all = []
  end

  def self.set_all(leads)
    @@all = leads
  end

  def self.clear_valid
    @@valid = []
  end

  def self.clear_duplicates
    @@duplicates = []
  end

  def self.all_sorted_by_date_desc
    @@all.sort do |leadA, leadB|
      leadB.entry_date <=> leadA.entry_date
    end
  end

  def self.valid
    @@valid
  end

  def self.duplicates
    @@duplicates
  end

  def self.duplicates_by_email_count
    @@duplicates_by_email_count
  end

  def self.reset_duplicates_by_email_count
    @@duplicates_by_email_count = 0
  end

  def self.duplicates_by_id_count
    @@duplicates_by_id_count
  end

  def self.reset_duplicates_by_id_count
    @@duplicates_by_id_count = 0
  end

  def self.removed_count
    @@all.length - @@valid.length
  end

  def is_duplicate?
    @@valid.any? do |valid_lead|
      id_exists = (valid_lead.id == self.id)
      email_exists = (valid_lead.email == self.email)
      value_match_found = false

      if id_exists
        @@duplicates_by_id_count += 1
        value_match_found = true
        valid_lead.previous_version[:duplicate_id_found] = true
      end

      if email_exists
        @@duplicates_by_email_count += 1
        value_match_found = true
        valid_lead.previous_version[:duplicate_email_found] = true
      end

      if value_match_found
        valid_lead.previous_version[:lead] = self
        @@duplicates << self
      end

      id_exists || email_exists
    end
  end

  def id
    @data['_id']
  end

  def email
    @data['email']
  end

  def entry_date
    @data['entryDate']
  end

  private

  def self.summary_msg_arr(with_colors=false)
    summary_header = "[SUMMARY]".ljust(40, "-")
    line_dashed = ("-" * 40)

    [
      "\n",
      with_colors ? summary_header.bold.yellow : summary_header,
      "\n\n",
      "Total potential leads: #{@@all.length}\n",
      "Total valid leads: #{@@valid.length}\n",
      "Duplicate leads by email: #{duplicates_by_email_count}\n",
      "Duplicate leads by id: #{duplicates_by_id_count}\n",
      "Leads removed: #{@@all.length - @@valid.length}",
      "\n\n",
      with_colors ? line_dashed.bold.yellow : line_dashed,
      "\n"
    ]
  end
end
