require "minitest/autorun"
require "minitest/hooks/test"
require "json"
require "date"
require_relative "./../lead.rb"

class TestLead < Minitest::Test
  include Minitest::Hooks

  def setup
    Lead.clear_valid
    Lead.clear_duplicates
    Lead.clear_all
    Lead.reset_duplicates_by_email_count
    Lead.reset_duplicates_by_id_count

    @leadA = Lead.new({
      "_id": "1",
      "email": "bill@bar.com",
      "firstName":  "John",
      "lastName": "Smith",
      "address": "888 Mayberry St",
      "entryDate": "2014-05-07T17:33:20+00:00"
    })
    @leadB = Lead.new({
      "_id": "1",
      "email": "coo@bar.com",
      "firstName":  "Ted",
      "lastName": "Jones",
      "address": "456 Neat St",
      "entryDate": "2014-05-07T17:32:20+00:00"
    })
    @leadC = Lead.new({
      "_id": "2",
      "email": "coo@bar.com",
      "firstName":  "Ted",
      "lastName": "Jones",
      "address": "456 Neat St",
      "entryDate": "2014-05-07T17:32:20+00:00"
    })
  end

  # called before all tests are run
  def before_all
    @file = "leads_fixture.json"
    @leads_from_file = JSON.parse(File.read(@file))["leads"]
  end

  def test_all_leads_array_should_be_populated_from_file
    Lead.load_leads_from_file(@file)
    assert_equal @leads_from_file.length, Lead.all.length
  end

  def test_all_leads_sorted_by_date
    Lead.load_leads_from_file(@file)

    most_recent_date_from_file = @leads_from_file.map do |lead|
      lead["entryDate"]
    end.max

    most_recent_date_from_imported = Lead.all.map do |lead|
      lead.entry_date
    end.max

    assert_equal most_recent_date_from_file, most_recent_date_from_imported
  end

  def test_store_valid_lead
    Lead.load_leads_from_file(@file)
    lead = Lead.all.first
    Lead.store_lead_if_valid(lead)

    assert_equal Lead.valid.length, 1
    assert_equal Lead.valid.first, lead
  end

  def test_storing_duplicate_lead
    Lead.load_leads_from_file(@file)
    lead = Lead.all.first
    Lead.store_lead_if_valid(lead)

    assert_equal lead.is_duplicate?, true
    assert_equal Lead.duplicates.length, 1
  end

  def test_previous_version_saved_with_duplicate_id
    # add first lead
    Lead.store_lead_if_valid(@leadA)
    # attempt to store lead with duplicate ID
    Lead.store_lead_if_valid(@leadB)

    assert_equal @leadA.previous_version[:lead], @leadB
    assert_equal @leadA.previous_version[:duplicate_id_found], true
  end

  def test_previous_version_saved_with_duplicate_email
    # add first lead
    Lead.store_lead_if_valid(@leadB)
    # attempt to store lead with duplicate ID
    Lead.store_lead_if_valid(@leadC)

    assert_equal @leadB.previous_version[:lead], @leadC
    assert_equal @leadB.previous_version[:duplicate_email_found], true
  end

  def test_should_generate_correct_leads_list
    Lead.load_leads_from_file("leads_fixture.json")

    assert_equal Lead.all.length, 5
    assert_equal Lead.valid.length, 0

    Lead.all_sorted_by_date_desc.each do |lead|
      Lead.store_lead_if_valid(lead)
    end

    assert_equal Lead.valid.length, 3
    assert_equal Lead.duplicates_by_email_count, 1
    assert_equal Lead.duplicates_by_id_count, 2
    assert_equal Lead.removed_count, 2
  end
end
