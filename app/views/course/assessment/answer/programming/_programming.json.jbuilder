submission = answer.submission
assessment = submission.assessment
question = answer.question.specific
last_attempt = last_attempt(answer)
auto_grading = last_attempt.try(:auto_grading).try(:specific)

json.fields do
  json.questionId answer.question_id
  json.id answer.acting_as.id
  json.files_attributes answer.files do |file|
    json.(file, :id, :filename)
    json.content submission.attempting? ? file.content : highlight_code_block(file.content, question.language)
  end
end

if answer.submitted? && job = answer.try(:auto_grading).try(:job)
  json.autograding do
    json.path job_path(job) if job.submitted?
    json.status job.status
  end
end

if answer.submitted? && !answer.auto_grading
  json.autograding do
    json.status :submitted
  end
end


can_read_tests = can?(:read_tests, submission)
show_private = can_read_tests || submission.published? && assessment.show_private?
show_evaluation = can_read_tests || submission.published? && assessment.show_evaluation?

test_cases_by_type = question.test_cases_by_type
test_cases_and_results = get_test_cases_and_results(test_cases_by_type, auto_grading)

displayed_test_case_types = ['public_test']
displayed_test_case_types << 'private_test' if show_private
displayed_test_case_types << 'evaluation_test' if show_evaluation

json.testCases do
  displayed_test_case_types.each do |test_case_type|
    json.set! test_case_type do
      if test_cases_and_results[test_case_type].present?
        json.array! test_cases_and_results[test_case_type] do |test_case, test_result|
          json.identifier test_case.identifier if can_grade
          json.expression test_case.expression
          json.expected test_case.expected
          if test_result
            json.output get_output(test_result) if can_grade
            json.passed test_result.passed?
          end
        end
      end
    end
  end

  if can_read_tests && auto_grading && auto_grading.exit_code && auto_grading.exit_code != 0
    json.(auto_grading, :stdout, :stderr)
  end
end

failed_test_cases_by_type = get_failed_test_cases_by_type(test_cases_and_results)

json.explanation do
  assessment = answer.submission.assessment
  if last_attempt
    explanations = []

    if failed_test_cases_by_type['public_test']
      failed_test_cases_by_type['public_test'].each do |test_case, test_result|
        explanations << simple_format(get_hint(test_case, test_result))
      end
      json.failureType 'public_test'

    elsif failed_test_cases_by_type['private_test']
      failed_test_cases_by_type['private_test'].each do |test_case, test_result|
        explanations << simple_format(get_hint(test_case, test_result))
      end
      json.failureType 'private_test'
    end

    json.correct last_attempt&.auto_grading && last_attempt.correct
    json.explanations explanations
  end
end

json.attemptsLeft answer.attempting_times_left if question.attempt_limit