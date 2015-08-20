class TasksController < SignedInController

  def index
    @new_task = Task.new
    @tasks = (current_user.tasks if current_user.respond_to? :tasks) || {}
    super
  end

  def create
    return unless params['task']['description']   # We don't store empty tasks.
    task = Task.create!(description: params['task']['description'],
                        user_id: current_user.id,
                        user: current_user)
    current_user.tasks.append task
    task.save!
    redirect_to tasks_path
  end

  def destroy
    Task.find(params[:id]).destroy
    redirect_to tasks_path
  end

  # Save the task list to OneDrive for Business.
  def cloud_save
    token = current_user.access_token('https://adamajmichael-my.sharepoint.com/')
    creation_endpt = URI("https://adamajmichael-my.sharepoint.com/_api/v1.0/me/files")
    http = Net::HTTP.new(creation_endpt.hostname, creation_endpt.port)
    http.use_ssl = true
    name = "TodoList-#{Time.now.to_i}.txt"
    creation_response = http.post(
      creation_endpt,
      JSON.unparse({ 'name' => name, 'type' => 'File' }),
      'authorization' => "Bearer #{token}",
      'content-type' => 'application/json')
    upload_response = http.post(
      "#{JSON.parse(creation_response.body)['@odata.id']}/uploadContent",
      current_user.tasks.map { |task| "TODO: #{task.description}" }.join("\n"),
      { 'authorization' => "Bearer #{token}" })
    if 200 <= upload_response.code.to_i && upload_response.code.to_i < 300
      flash[:notice] = "Task list saved to OneDrive for Business as #{name}."
    else
      flash[:notice] = "Failed to write task list to OneDrive for Business."
    end
    redirect_to tasks_path
  rescue ADAL::TokenRequest::UserCredentialError
    redirect_to User.authorization_request_url.to_s
  end

  private

  def current_user
    User.find_by_id(session['user_id'])
  end

  def task_params
    params.require(:task).permit(:description)
  end
end
