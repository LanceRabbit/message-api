# app.rb
require 'sinatra'
require 'line/bot'
require 'dotenv/load'
require './google_sheet'


def date_pattern
  /[0-2]{1}[0-9]{1}\:[0-5]{1}[0-9]{1}/
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_id = ENV["LINE_CHANNEL_ID"]
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

def process(content)
  case content
  when "Show"
    data = GoogleSheet.get_sheet_array_from_google_sheet.last
    keys = [:Date, :Time, :Full, :Used, :Stool, :Food]
    data = data.each_with_index.map  do |value, index|
      "#{keys[index]}: #{value}"
    end.join(",\n")
    "最後一筆資料: \n#{data}"
  when "Delete"
    GoogleSheet.clear_data_from_spreadsheet
    "Delete Data Successfully"
  else
    # Save data
    if date_pattern.match(content.split(' ')[0])
      GoogleSheet.append_data_to_spreadsheet(content.split(' '))
      "寫入資料成功: \n#{content}"
    else
      return content
    end
  end

end

get '/sheet' do
  GoogleSheet.get_sheet_array_from_google_sheet
  "OK"
end

post '/callback' do
  body = request.body.read
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  p events
  events.each do |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        # puts "msg: #{event.message['text']}"
        # p "MSG:::"
        # p event.message['text'].split(' ')
        text = process(event.message['text'])
        message = {
          type: 'text',
          text: text
        }
        client.reply_message(event['replyToken'], message)
      # when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
      #   response = client.get_message_content(event.message['id'])
      #   tf = Tempfile.open("content")
      #   tf.write(response.body)
      end
    end
  end

  # Don't forget to return a successful response
  "OK"
end