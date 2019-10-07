require "minitest/autorun"
require "minitest/hooks/test"
require "json"
require "date"
require_relative "./../lead.rb"
require_relative "./../lead_collection.rb"

class TestLead < Minitest::Test
  include Minitest::Hooks

  def before_all
    unless (Dir.getwd.include?("tests"))
      Dir.chdir("tests")
    end

    @file = "leads_fixture.json"
    @leads_from_file = LeadCollection.parse_json_from_leads_file(@file)
    @leadA = Lead.new(@leads_from_file.first)
    @leadB = Lead.new(@leads_from_file[1])
    @leadC = Lead.new(@leads_from_file[2])
  end

  def test_all_leads_array_should_be_populated_from_file
    lead_collection = LeadCollection.new
    lead_collection.initialize_leads_as_lead_objects(@leads_from_file)
    assert_equal @leads_from_file.length, lead_collection.all.length
  end

  def test_all_leads_sorted_by_date
    lead_collection = LeadCollection.new
    lead_collection.initialize_leads_as_lead_objects(@leads_from_file)

    most_recent_date_from_file = @leads_from_file.map do |lead|
      lead["entryDate"]
    end.max

    most_recent_date_from_imported = lead_collection.sorted_by_date_desc.map do |lead|
      lead.entry_date
    end.max

    assert_equal most_recent_date_from_file, most_recent_date_from_imported
  end

  def test_find_valid_lead
    lead_collection = LeadCollection.new
    lead_collection.valid << @leadA
    valid_lead = lead_collection.find_valid_lead(@leadA)

    assert_instance_of Lead, valid_lead
    assert_equal valid_lead, @leadA
  end

  def test_find_valid_lead_is_nil
    lead_collection = LeadCollection.new
    valid_lead = lead_collection.find_valid_lead(@leadA)

    assert_nil valid_lead
  end

  def test_store_valid_lead_is_successful
    lead_collection = LeadCollection.new
    result = lead_collection.store_lead_if_valid(@leadA)

    assert_equal result[:success], true
    assert_equal lead_collection.valid.length, 1
  end

  def test_store_valid_lead_fails
    lead_collection = LeadCollection.new
    lead_collection.valid << @leadA
    result = lead_collection.store_lead_if_valid(@leadA)

    assert_equal result[:existing_lead], @leadA
    assert_equal result[:success], false
  end

  def test_has_duplicate_email_is_true
    result = @leadB.has_duplicate_email?(@leadC)

    assert_equal result, true
  end

  def test_has_duplicate_email_is_false
    result = @leadA.has_duplicate_email?(@leadB)

    assert_equal result, false
  end

  def test_has_duplicate_id_is_true
    result = @leadA.has_duplicate_id?(@leadB)

    assert_equal result, true
  end

  def test_has_duplicate_id_is_false
    result = @leadA.has_duplicate_id?(@leadC)

    assert_equal result, false
  end

  def test_lead_converts_to_hash
    lead_as_hash = {
      id: @leadA.id,
      email: @leadA.email,
      first_name: @leadA.first_name,
      last_name: @leadA.last_name,
      address: @leadA.address,
      entry_date: @leadA.entry_date
    }
    result = @leadA.to_h

    assert_equal result, lead_as_hash
  end

  def test_changes_stored_from_previous_lead
    @leadA.compare_and_store_changes_against(@leadB)

    assert_nil @leadA.previous_values[:id]
    assert_equal @leadA.previous_values[:email][:from], @leadB.email
  end

  def test_duplicate_counts_increase
    lead = Lead.new(@leads_from_file[3])
    lead_collection = LeadCollection.new
    lead.compare_and_store_changes_against(lead)
    lead_collection.update_duplicate_counts(lead)

    assert_equal lead_collection.duplicates_by_id_count, 1
    assert_equal lead_collection.duplicates_by_email_count, 1
  end

  def test_summary_is_accurate
    lead_collection = LeadCollection.new
    lead_collection.initialize_leads_as_lead_objects(@leads_from_file)

    lead_collection.sorted_by_date_desc.each do |lead|
      result = lead_collection.store_lead_if_valid(lead)

      if result[:success] == false
        valid_lead = result[:existing_lead]
        valid_lead.compare_and_store_changes_against(lead)
        lead_collection.update_duplicate_counts(valid_lead)
      end
    end

    summary = lead_collection.summary
    assert_equal summary[:all_count], 6
    assert_equal summary[:valid_count], 4
    assert_equal summary[:duplicates_by_email_count], 1
    assert_equal summary[:duplicates_by_id_count], 2
    assert_equal summary[:removed_count], 2
  end

  def test_change_log_is_accurate
    fixture_file = "change_log_fixture.txt"
    change_log_file = "change_log.txt"
    lead_collection = LeadCollection.new
    lead_collection.initialize_leads_as_lead_objects(@leads_from_file)

    lead_collection.sorted_by_date_desc.each do |lead|
      result = lead_collection.store_lead_if_valid(lead)

      if result[:success] == false
        valid_lead = result[:existing_lead]
        valid_lead.compare_and_store_changes_against(lead)
        lead_collection.update_duplicate_counts(valid_lead)
      end
    end

    lead_collection.update_change_log
    # remove timestamp from files
    change_log_fixture_content = File.readlines(fixture_file)[1...-1]
    generated_file_content = File.readlines(change_log_file)[1...-1]

    assert_equal change_log_fixture_content, generated_file_content
    FileUtils.rm(change_log_file)
  end

  def test_valid_leads_file_is_accurate
    fixture_file = "valid_leads_fixture.json"
    lead_collection = LeadCollection.new
    lead_collection.initialize_leads_as_lead_objects(@leads_from_file)

    lead_collection.sorted_by_date_desc.each do |lead|
      result = lead_collection.store_lead_if_valid(lead)

      if result[:success] == false
        valid_lead = result[:existing_lead]
        valid_lead.compare_and_store_changes_against(lead)
        lead_collection.update_duplicate_counts(valid_lead)
      end
    end

    lead_collection.create_valid_leads_file
    generated_file = Dir.glob("valid-leads-*").first
    assert_equal FileUtils.compare_file(fixture_file, generated_file), true
    FileUtils.rm(generated_file)
  end
end
