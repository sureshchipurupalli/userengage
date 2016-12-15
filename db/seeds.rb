ActiveRecord::Base.connection.execute('truncate table platforms')
['Android', 'iOS'].each do |platform|
  Platform.create(name:platform, deleted: 0)
end

ActiveRecord::Base.connection.execute('truncate table roles')
Role.create(name:'company',description: 'can create companies and apps')
Role.create(name:'app',description: 'can create only apps but not companies')


ActiveRecord::Base.connection.execute('truncate table feedback_categories')
FeedbackCategory.create(name:'Report Crash', description: 'Report a crash or exception', status: 1, deleted: false)
FeedbackCategory.create(name:'Request Feature', description: 'Request for a new feature', status: 1, deleted: false)




# create two org settings by default while creating org
# 1. can create users at org level
# 2. can create users at app level