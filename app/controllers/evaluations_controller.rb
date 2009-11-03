class EvaluationsController < ApplicationController
  before_filter :require_user
  append_before_filter :authorized?

  def show
    @course_term  = CourseTerm.find(params[:id])

    respond_to do |format|
      format.html { }
      format.js {    
        @assignments  = Assignment.paginate_by_course_term_id(@course_term,
          :per_page => 6,
          :page     => params[:page],
          :order    => "due_date DESC, created_at ASC")
        @scalerange   = ScaleRange.find_all_by_grading_scale_id(@course_term.course.grading_scale_id)

        render :partial => "grades"
      }
    end
  end

  def update
    respond_to do |format|
      # This data is only updated via AJAX
      format.html { render :nothing => true}
      
      format.js {
        # What are we updating, skills or grades?
        if params[:skill]
          evaluation = SupportingSkillEvaluation.find_or_create_by_student_id_and_course_term_skill_id(
            params[:student], params[:skill], :include => [:students, :course_term_skills])

          evaluation.score = params[:score]

        elsif params[:assignment]
          evaluation = AssignmentEvaluation.find_or_create_by_student_id_and_assignment_id(
            params[:student], params[:assignment])

          # If the score is blank then delete the gradation row
          if params[:score].empty?
            AssignmentEvaluation.destroy(evaluation)
          else
            evaluation.points_earned = params[:score]
          end
        end

        # Save the record
        evaluation.save ? status = 200 : status = 444

        # Return the necessary info
        if params[:skill]
          render :nothing => true
        elsif params[:assignment]
          grade = CourseTerm.find(params[:id]).calculate_grade(params[:student])
          render :text => "#{grade[:letter]} (#{grade[:score].round}%)", :status => status
        end
      }
    end
  end

end
