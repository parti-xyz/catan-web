class ReportsController < ApplicationController
  def new
    @report = Report.new(report_params)

    render(layout: nil) if helpers.explict_front_namespace?
  end

  def create
    @report = Report.new(report_params)
    @report.user = current_user

    render_404 && return if @report.reportable_type&.safe_constantize.blank?

    if @report.save
      if helpers.explict_front_namespace?
        flash.now[:notice] = t('activerecord.successful.messages.reported')

        response_header_modal_command('close')
        head(204)
      end
    else
      errors_to_flash(@report)
    end
  end

  private

  def report_params
    params.require(:report).permit(:reason, :reportable_id, :reportable_type)
  end
end