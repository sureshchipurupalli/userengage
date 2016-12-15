class User < ActiveRecord::Base
  include Registration
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  has_many :organisations
  mount_uploader :profile_pic, ProfileUploader

  def after_confirmation
    post_activation_setup(id) # create required org and role setup.
  end

  def name
    if first_name.present? || last_name.present?
       first_name + " " + last_name
    else
      email.slice(0..1).upcase
    end
  end

  def initials
    if first_name.present? || last_name.present?
      first_name.slice(0..0).upcase + last_name.slice(0..0).upcase
    else
      email.slice(0..1).upcase
    end
  end

end
