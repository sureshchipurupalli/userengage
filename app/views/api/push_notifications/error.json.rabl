node(:success) { false }

node :errors do
  @errors.map do |error|
    { :code => error[:code], :message => error[:message] }
  end
end

