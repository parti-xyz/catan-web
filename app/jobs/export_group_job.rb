class ExportGroupJob < ApplicationJob
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(group_slug)
    group = Group.find_by!(slug: group_slug)

    xlsx_package = Axlsx::Package.new
    xlsx_workbook = xlsx_package.workbook

    issues_base = group.issues
    posts_base = Post.where(issue: group.issues)
    comments_base = Comment.where(post: Post.where(issue: group.issues))

    total(issues_base.count + posts_base.count + comments_base.count)

    current_index = 0

    xlsx_workbook.add_worksheet(name: 'Channels') do |worksheet|
      worksheet.add_row %w[ID 제목 카테고리 휴면여부]
      issues_base.includes(:category).find_each do |issue|
        worksheet.add_row [issue.id, issue.title, issue.category&.name, issue.iced?]

        current_index += 1
        at current_index
      end
    end

    xlsx_workbook.add_worksheet(name: 'Posts') do |worksheet|
      worksheet.add_row %w[ID 제목 내용 채널ID 회원닉네임 생성일]
      posts_base.includes(:user).find_each do |post|
        worksheet.add_row [post.id, post.title, ActionController::Base.helpers.strip_tags(post.body), post.issue_id, post.user.nickname, post.created_at]

        current_index += 1
        at current_index
      end
    end

    xlsx_workbook.add_worksheet(name: 'Comments') do |worksheet|
      worksheet.add_row %w[ID 내용 채널ID 게시글ID 회원닉네임 생성일]
      comments_base.includes(:user, :post).find_each do |comment|
        worksheet.add_row [comment.id, comment.body, comment.post.issue_id, comment.post.id, comment.user.nickname, comment.created_at]

        current_index += 1
        at current_index
      end
    end

    serialize_xlsx(xlsx_package, group_slug)
  end

  def self.export_file_name(group_slug, job_id)
    "group_#{group_slug}_#{job_id}.xlsx"
  end

  def self.export_base_path
    Rails.root.join('tmp', 'exports')
  end

  def self.export_file_path(group_slug, job_id)
    export_base_path.join(export_file_name(group_slug, job_id))
  end

  def self.s3_object(group_slug, job_id)
    return unless self.remote_exportable?

    s3_client = Aws::S3::Client.new(
      region: ENV['PRIVATE_S3_REGION'],
      access_key_id: ENV['PRIVATE_S3_ACCESS_KEY'],
      secret_access_key: ENV['PRIVATE_S3_SECRET_KEY'],
    )
    Aws::S3::Object.new(ENV['PRIVATE_S3_BUCKET'], "exports/#{Rails.env}/#{ExportGroupJob.export_file_name(group_slug, job_id)}", client: s3_client)
  end

  def self.remote_exportable?
    ENV['SIDEKIQ'] == 'true'
  end

  private

  def serialize_xlsx(xlsx_package, group_slug)
    if ExportGroupJob.remote_exportable?
      ExportGroupJob.s3_object(group_slug, self.jid).upload_stream do |write_stream|
        write_stream.binmode
        write_stream.write(xlsx_package.to_stream().read())
      end
    else
      FileUtils.mkdir_p(ExportGroupJob.export_base_path) unless File.directory?(ExportGroupJob.export_base_path)
      xlsx_package.serialize ExportGroupJob.export_file_path(group_slug, self.jid)
    end
  end
end
