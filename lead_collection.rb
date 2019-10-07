require "json"
require "colorize"
require_relative "lead"

class LeadCollection
  attr_accessor :all
  attr_reader :valid, :duplicates_by_id_count, :duplicates_by_email_count

  def initialize()
    @all = []
    @valid = []
    @duplicates_by_id_count = 0
    @duplicates_by_email_count = 0
  end

  def self.parse_json_from_leads_file(file)
    JSON.parse(File.read(file))["leads"]
  end

  def initialize_leads_as_lead_objects(leads)
    leads.each do |lead|
      @all << Lead.new(lead)
    end
  end

  # if id or email does not have a 'previous_value'
  # we can assume they were duplicates and a change
  # was not made
  def update_duplicate_counts(lead)
    unless (lead.previous_values[:id])
      @duplicates_by_id_count += 1
    end

    unless (lead.previous_values[:email])
      @duplicates_by_email_count += 1
    end
  end

  def sorted_by_date_desc
    @all.sort do |leadA, leadB|
      leadB.entry_date <=> leadA.entry_date
    end
  end

  def store_lead_if_valid(lead)
    existing_lead = self.find_valid_lead(lead)
    result = { success: true }

    if existing_lead
      result[:success] = false
      result[:existing_lead] = existing_lead
    else
      self.valid << lead
    end

    result
  end

  def find_valid_lead(lead)
    match = nil

    index = @valid.each_with_index do |valid_lead|
      id_match = (valid_lead.id == lead.id)
      email_match = (valid_lead.email == lead.email)

      if (id_match || email_match)
        match = valid_lead
      end
    end

    match
  end

  def output_summary_to_cli
    puts self.summary_msg_arr(with_colors=true).join
  end

  def summary
    {
      all_count: @all.length,
      valid_count: @valid.length,
      duplicates_by_email_count: @duplicates_by_email_count,
      duplicates_by_id_count: @duplicates_by_id_count,
      removed_count: @all.length - @valid.length
    }
  end

  def create_valid_leads_file
    formatted_date = DateTime.now.strftime("%Y%m%d-%H:%M:%S")
    file_name = "valid-leads-#{formatted_date}.json"

    File.open(file_name, "w+") do |file|
      file.puts JSON.pretty_generate(@valid.map(&:to_h))
    end

    file_name
  end

  def output_valid_leads_file_path(file_name)
    puts "\nValid leads file has been generated:".blue.bold + " #{file_name}"
  end

  def output_change_log_file_info
    puts "\n"
    puts "See change log for more details: ".blue.bold + "change_log.txt"
    puts "\n"
  end

  def update_change_log
    File.open("change_log.txt", "a") do |file|
      formatted_date = DateTime.now.strftime("%Y%m%d-%H:%M:%S")
      file.puts "[LOG_ENTRY: #{formatted_date}] ".ljust(85, "-")
      file.puts "\n"

      @valid.each do |lead|
        unless lead.previous_values.empty?
          previous_values = lead.previous_values

          file.puts "[LEAD UPDATED]\n".ljust(100, "-")

          unless previous_values[:email]
            file.puts "DUPLICATE EMAIL FOUND: #{lead.email}"
          end

          unless previous_values[:id]
            file.puts "DUPLICATE ID FOUND: #{lead.id}"
          end

          file.puts "\n"
          file.puts "UPDATED LEAD:"
          file.puts JSON.pretty_generate(lead.to_h)
          file.puts "\n"
          file.puts "FIELD CHANGES:"

          previous_values.keys.each do |key|
            next if previous_values[key].nil?

            old_val = previous_values[key][:from]
            new_val = previous_values[key][:to]

            file.puts "#{key} field changed from \"#{old_val}\" to \"#{new_val}\""
          end

          file.puts "\n"
        end
      end

      file.puts self.summary_msg_arr.join
    end
  end

  protected

  def summary_msg_arr(with_colors=false)
    summary_header = "[SUMMARY]".ljust(40, "-")
    line_dashed = ("-" * 40)
    summary = self.summary

    [
      "\n",
      with_colors ? summary_header.bold.yellow : summary_header,
      "\n\n",
      "Total potential leads: #{summary[:all_count]}\n",
      "Total valid leads: #{summary[:valid_count]}\n",
      "Duplicate leads by email: #{summary[:duplicates_by_email_count]}\n",
      "Duplicate leads by id: #{summary[:duplicates_by_id_count]}\n",
      "Leads removed: #{summary[:removed_count]}",
      "\n\n",
      with_colors ? line_dashed.bold.yellow : line_dashed,
      "\n"
    ]
  end
end
