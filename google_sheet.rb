# frozen_string_literal: true
require 'google/apis/sheets_v4'
# require 'googleauth'
require 'dotenv/load'

class GoogleSheet
  def self.get_sheet_array_from_google_sheet(options = {})
    service = get_service

    service.get_spreadsheet_values(
      ENV["GOOGLE_SHEET_ID"],
      "Daily!A2:F20000"
    ).values
    # p data.last
  end

  def self.append_data_to_spreadsheet(values)
    service = get_service

    #Add rows to spreadsheet
    values = values.each_with_index.map do |value, index|
      value = value.to_i if [1,2].include?(index)
      value
    end
    values.unshift(Date.today.strftime("%Y/%m/%d"))
    # values = [Date.parse("2020-09-07"), "13:41", "210".to_i, "180".to_i, "", "🥦"]
    response = service.append_spreadsheet_value(
      ENV["GOOGLE_SHEET_ID"], "Daily!A:F",
      {"values": [values]},
      value_input_option: "USER_ENTERED"
    )
    # puts response.to_json
  end

  def self.clear_data_from_spreadsheet
    service = get_service
    index = get_sheet_array_from_google_sheet.size + 1
    response = service.clear_values(ENV["GOOGLE_SHEET_ID"], "Daily!A#{index}:F#{index}")
    # puts response.to_json
  end

  def self.move_data_to_other_sheet
    service = get_service

    data = service.get_spreadsheet_values(
      ENV["GOOGLE_SHEET_ID"],
      "Daily!A2:F"
    ).values

    data.each do |content|
      content = content.each_with_index.map do |value, index|
        value = value.to_i if [2,3].include?(index)
        value
      end
      service.append_spreadsheet_value(
        ENV["GOOGLE_SHEET_ID"], "Detail!A:F",
        {"values": [content]},
        value_input_option: "RAW"
      )
    end

    service.clear_values(ENV["GOOGLE_SHEET_ID"], "Daily!A2:F")

  end

  def self.get_last_data
    data = get_sheet_array_from_google_sheet

    return "本日尚未新增資料！" if data.nil?

    keys = [:Date, :Time, :Full, :Used, :Stool, :Food]
    data = data.last.each_with_index.map  do |value, index|
      "#{keys[index]}: #{value}"
    end.join(",\n")
    "最後一筆資料: \n#{data}"
  end

  def self.group_by_field(date)
    service = get_service
    data = service.get_spreadsheet_values(
      ENV["GOOGLE_SHEET_ID"],
      "Daily!A2:F20000"
    ).values

    return 0 if data.nil?

    total = data.select do |content|
      content[0] == date
    end.inject(0) do |sum, content|
      sum += content[3].to_i
    end
  end

  def self.save_user_data(values)
    service = get_service
    service.append_spreadsheet_value(
      ENV["GOOGLE_SHEET_ID"], "Users!A:C",
      {"values": [values]},
      value_input_option: "USER_ENTERED"
    )
  end

  def self.save_user_data(values, status)
    service = get_service
    data = get_user_data
    index = data.map {|user| user[0]}.find_index(values[0])
    if index
      user = data[index]
      user[2] = status
      service.update_spreadsheet_value(
        ENV["GOOGLE_SHEET_ID"], "Users!A#{index+1}:C#{index+1}",
        {"values": [user]},
        value_input_option: "USER_ENTERED"
      )
    else
      values = values.push(status)
      service.append_spreadsheet_value(
        ENV["GOOGLE_SHEET_ID"], "Users!A:C",
        {"values": [values]},
        value_input_option: "USER_ENTERED"
      )
    end
  end

  def self.get_user_data
    service = get_service
    service.get_spreadsheet_values(
      ENV["GOOGLE_SHEET_ID"], "Users!A:C",
    ).values
  end

  private

  def self.get_service
    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = get_google_auth
    service
  end

  def self.get_google_auth
    scope = [Google::Apis::SheetsV4::AUTH_SPREADSHEETS]
    file = File.open("google-api-key.json", 'r')
    authorization = Google::Auth::ServiceAccountCredentials.make_creds({:json_key_io=> file, :scope => scope})
  end
end

# GoogleSheet.get_sheet_array_from_google_sheet

# GoogleSheet.append_data_to_spreadsheet

# GoogleSheet.clear_data_from_spreadsheet

# GoogleSheet.move_data_to_other_sheet
# GoogleSheet.group_by_field(Date.today.to_s)
