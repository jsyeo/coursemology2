# frozen_string_literal: true
class Course::Achievement < ActiveRecord::Base
  acts_as_conditional
  mount_uploader :badge, ImageUploader

  after_initialize :set_defaults, if: :new_record?

  belongs_to :course, inverse_of: :achievements
  has_many :course_user_achievements, class_name: Course::UserAchievement.name,
                                      inverse_of: :achievement, dependent: :destroy
  has_many :achievement_conditions, class_name: Course::Condition::Achievement.name,
                                    inverse_of: :achievement, dependent: :destroy
  # Due to the through relationship, destroy dependent had to be added for course users in order for
  # UserAchievement's destroy callbacks to be called, However, this destroy dependent will not
  # actually remove the course users when the Achievement object is destroyed.
  # http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html
  has_many :course_users, through: :course_user_achievements, class_name: CourseUser.name,
                          dependent: :destroy

  default_scope { order(weight: :asc) }

  def to_partial_path
    'course/achievement/achievements/achievement'.freeze
  end

  # Set default values
  def set_defaults
    self.weight ||= 10
  end

  # Returns if achievement is manually or automatically awarded.
  #
  # @return [Boolean] Whether the achievement is manually awarded.
  def manually_awarded?
    # TODO: Correct call should be conditions.empty?, but that results in an
    # exception due to polymorphism. To investigate.
    specific_conditions.empty?
  end

  def permitted_for!(course_user)
    return if conditions.empty?
    course_users << course_user unless course_users.exists?(course_user.id)
  end

  def precluded_for!(course_user)
    course_users.delete(course_user) if course_users.exists?(course_user.id)
  end
end
