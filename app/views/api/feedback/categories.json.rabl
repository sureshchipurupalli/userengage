node(:success) { true }

node :categories do
  @categories.map do |category|
    { :id => category[:id], :name => category[:name], :description => category[:description] }
  end
end