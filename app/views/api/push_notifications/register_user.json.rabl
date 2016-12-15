node(:success) { true }

node :messages do
  @messages.map do |message|
    { :code => message[:code], :message => message[:message] }
  end
end

if @user_unique_key.present?
    node(:user_unique_id) {@user_unique_key}
end