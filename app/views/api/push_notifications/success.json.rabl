node(:success) { true }

node :messages do
  @messages.map do |message|
    { :code => message[:code], :message => message[:message] }
  end
end

