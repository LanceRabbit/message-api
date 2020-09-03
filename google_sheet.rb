require 'google/apis/sheets_v4'
require 'googleauth'

class GoogleSheet
  def self.get_sheet_array_from_google_sheet(options = {})
    p @sheet_id
    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = get_google_auth
    data = service.get_spreadsheet_values(
      "sheet_id",
      "Sheet!A2:E20000"
    ).values
    p data
  end

  def self.append_data_to_spreadsheet
    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = get_google_auth

    #Add rows to spreadsheet
    range_name = ["A1:E1"]
    values = ["", "13:41", "210", "🥦"]
    values_range = Google::Apis::SheetsV4::ValueRange.new(values: values)

    response= service.append_spreadsheet_value(
      "sheet_id", "Sheet!A:E",
      {"values": [values]},
      value_input_option: "RAW"
    )

    puts response.to_json
  end

  private

  def self.get_google_auth
    scope = [Google::Apis::SheetsV4::AUTH_SPREADSHEETS]
    file = File.open("google-api-key.json", 'r')
    authorization = Google::Auth::ServiceAccountCredentials.make_creds({:json_key_io=> file, :scope => scope})
  end
end

# GoogleSheet.get_sheet_array_from_google_sheet

GoogleSheet.append_data_to_spreadsheet
