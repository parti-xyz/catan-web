class Admin::ExportsController < Admin::BaseController
  before_action :set_use_pack_js

  def index
  end

  def group
    group_slug = params[:group_slug]
    unless Group.exists?(slug: group_slug)
      flash.now[:notice] = '해당 그룹이 없습니다'
      render_404 and return
    end

    respond_to do |format|
      format.json do
        job_id = ExportGroupJob.perform_async(group_slug)

        job_status = Sidekiq::Status::status(job_id)
        Rails.logger.debug("job_status: #{job_status}")
        render json: {
          jobId: job_id,
          groupSlug: group_slug
        }
      end
    end
  end

  def status
    respond_to do |format|
      format.json do
        job_id = params[:job_id]
        job_traking = Sidekiq::Status.get_all(job_id).symbolize_keys

        if job_traking.present?
          render json: {
            status: job_traking[:status],
            percentage: job_traking[:pct_complete]
          }
        else
          job_status = Sidekiq::Status.status(job_id)
          Rails.logger.debug("job_status: #{job_status}")

          render json: {
            status: job_status || 'not-found',
            percentage: 0
          }
        end
      end
    end
  end

  def download
    group_slug = params[:group_slug]
    job_id = params[:job_id]

    filename = "parti_group_#{group_slug}_#{Time.current.strftime("%Y%m%d_%H%M%S")}.xlsx"

    respond_to do |format|
      format.xlsx do
        if ExportGroupJob.remote_exportable?
          data = open(ExportGroupJob.s3_object(group_slug, job_id).presigned_url(:get, expires_in: 3600))
          send_data data.read, filename: filename, type: :xlsx, disposition: 'attachment', stream: 'true', buffer_size: '4096'
        else
          export_file_path = ExportGroupJob.export_file_path(group_slug, job_id)
          send_file export_file_path, type: :xlsx, filename: filename
        end
      end
    end
  end
end
