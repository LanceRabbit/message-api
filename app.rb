# frozen_string_literal: true
require_relative './lib/google_sheet'
require_relative './lib/bot'
require 'sinatra'
require 'dotenv/load'
require 'line/bot'
set :environment, 'production'
set :bind, "0.0.0.0"
port = ENV["PORT"] || "8080"
set :port, port

def time_pattern
  /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/
end

def get_user_profile(userId)
  response = Bot.client.get_profile(userId)
  case response
  when Net::HTTPSuccess then
    contact = JSON.parse(response.body)
    # p contact
    # p contact['displayName']
    # p contact['pictureUrl']
    # p contact['statusMessage']
    [userId, contact['displayName']]
  else
    p "#{response.code} #{response.body}"
  end
end

def process(content)
  case content
  when "Example"
    <<-WORD
    ===說明===
    時間
    泡奶量
    喝奶量
    大便
    副食品
    ===範本===
    13:41
    210
    180
    -
    🥦
    WORD
  when "Show"
    GoogleSheet.get_last_data
  when "Delete"
    GoogleSheet.clear_data_from_spreadsheet
    "刪除資料成功"
  when "Total Milk"
    total = GoogleSheet.group_by_field(Date.today.strftime("%Y/%m/%d"))
    "今天喝了 #{total} ml 的配方奶"
  else
    # Save data
    if time_pattern.match(content.split(' ')[0])
      GoogleSheet.append_data_to_spreadsheet(content.split(' '))
      "寫入資料成功: \n#{content}"
    else
      return content
    end
  end

end

get '/daily_job' do
  # p request
  # data = GoogleSheet.get_sheet_array_from_google_sheet.last
  GoogleSheet.move_data_to_other_sheet
  # p data
  "OK"
end

post '/callback' do
  body = request.body.read
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless Bot.client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = Bot.client.parse_events_from(body)
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
        Bot.client.reply_message(event['replyToken'], message)
      # when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
      #   response = client.get_message_content(event.message['id'])
      #   tf = Tempfile.open("content")
      #   tf.write(response.body)
      end
    when Line::Bot::Event::Follow
      data = get_user_profile(event['source']['userId'])
      GoogleSheet.save_user_data(data, "Follow")
    when Line::Bot::Event::Unfollow
      data = [event['source']['userId']]
      GoogleSheet.save_user_data(data, "Unfollow")
    end
  end

  # Don't forget to return a successful response
  "OK"
end
