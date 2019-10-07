require "json"
require "date"
require "colorize"

class Lead
  attr_reader :previous_values, :id, :email, :first_name, :last_name,
              :address, :entry_date

  def initialize(lead)
    @id = lead["_id"]
    @email = lead["email"]
    @first_name = lead["firstName"]
    @last_name = lead["lastName"]
    @address = lead["address"]
    @entry_date = lead["entryDate"]
    @previous_values = {}
  end

  def compare_and_store_changes_against(lead)
    lead = lead.to_h
    current_lead = self.to_h

    current_lead.keys.each do |key|
      if (current_lead[key] != lead[key])
        @previous_values[key] = Lead.create_from_to_hash(
          lead[key],
          current_lead[key]
        )
      end
    end
  end

  def has_duplicate_email?(lead)
    self.email == lead.email
  end

  def has_duplicate_id?(lead)
    self.id == lead.id
  end

  def to_h
    {
      id: @id,
      email: @email,
      first_name: @first_name,
      last_name: @last_name,
      address: @address,
      entry_date: @entry_date
    }
  end

  private

  def self.create_from_to_hash(from, to)
    {
      from: from,
      to: to
    }
  end
end
