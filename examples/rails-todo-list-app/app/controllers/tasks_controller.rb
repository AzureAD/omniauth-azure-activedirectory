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

  private

  def current_user
    User.find_by_id(session['user_id'])
  end

  def task_params
    params.require(:task).permit(:description)
  end
end
