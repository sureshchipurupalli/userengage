module Device
  class Notification
    include ApplicationHelper
    # Mandatory Attribute
    # Setter , getter methods
    attr_accessor :title
    attr_accessor :body
    attr_accessor :sound
    # attr_accessor :push_notification_token
    # attr_accessor :platform_id
    # attr_accessor :os_version

    # Common Attributes for iOS, Android but not Required
    attr_accessor :priority
    attr_accessor :content_available
    attr_accessor :expiration_time

    # Optional Attributes
    attr_accessor :icon
    attr_accessor :badge
    attr_accessor :tag
    attr_accessor :collapse_key
    attr_accessor :color
    attr_accessor :click_action
    attr_accessor :actions
    attr_accessor :notification_key
    attr_accessor :data
    attr_accessor :errors
    attr_accessor :delay_while_idle

    # Notification Response
    attr_accessor :success
    attr_accessor :response_code
    attr_accessor :response_text
    attr_accessor :retry_count
    attr_accessor :sent_at

    def initialize
      @errors = []
    end

    # Override Setters Method for validations
    def title=(value)
      if value
        @title = value if value.is_a? String
      end
    end

    def body=(value)
      if value
        @body = value if value.is_a? String
      end
    end

    def push_notification_token=(value)
      if value.is_a? String
        @push_notification_token = value
      end
    end

    def platform_id=(value)
      if value.is_a? Integer
        @platform_id = value
      end
    end

    def os_version=(value)
      if value.is_a? String
        @os_version = value
      end
    end

    def sound=(value)
      if value
        @sound = value if value.is_a? String
        @sound = "1.aiff" if value.is_a?(TrueClass)
      end
    end

    def priority=(value)
      if value
        @priority = value if value.is_a? Integer
      end
    end

    def content_available=(value)
      if value
        @content_available = value
      end
    end

    def expiration_time=(value)
      if value
        @expiration_time = value if value.is_a? Integer
      end
    end

    def color=(value)
      if value
        @color = value if value.is_a? String
      end
    end

    def click_action=(value)
      if value
        @click_action = value if value.is_a? String
      end
    end

    def collapse_key=(value)
      if value
        @collapse_key = value if value.is_a? String
      end
    end

    def icon=(value)
      if value
          @icon = value if value.is_a? String
      end
    end

    def notification_key=(value)
      if value
        @notification_key = value if value.is_a? String
      end
    end

    def actions=(value)
      if value
        @actions = value if value.is_a? JSON
      end
    end

    def badge=(value)
      if value
        @badge = value if value.is_a? Integer
      end
    end

    def tag=(value)
      if value
        @tag = value if value.is_a? Integer
      end
    end

    def data=(value)
      if value
        @data = value if is_json? value
      end
    end

    def delay_while_idle=(value)
      if value
        @delay_while_idle = value
      end
    end

  end

end