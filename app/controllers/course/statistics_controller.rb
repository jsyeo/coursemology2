# frozen_string_literal: true
class Course::StatisticsController < Course::ComponentController
  before_action :authorize_read_statistics!

  def student
    preload_levels
    course_users = current_course.course_users.with_approved_state.includes(:groups)
    staff = course_users.staff.without_phantom_users
    all_students = course_users.students.ordered_by_experience_points
    @phantom_students, @students = all_students.partition(&:phantom?)
    @service = Course::StudentStatisticsService.new(staff)
  end

  def staff
    @staffs = current_course.course_users.with_approved_state.teaching_assistant_and_manager.
              without_phantom_users.ordered_by_average_marking_time
  end

  private

  def authorize_read_statistics!
    authorize!(:read_statistics, current_course)
  end

  # Pre-loads course levels to avoid N+1 queries when course_user.level_numbers are displayed.
  def preload_levels
    current_course.levels.to_a
  end
end
