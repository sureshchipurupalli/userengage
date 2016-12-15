class ProcessCampaign
  extend PushNotificationGroups
  @queue = :campaign

  def self.perform
    puts 'start'
    puts 'Hi ' + Time.now.to_s
    get_campaigns
    puts 'end'
  end
end