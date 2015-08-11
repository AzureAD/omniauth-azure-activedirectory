class Task < ActiveRecord::Base
  belongs_to :user
  validates :user_id, :description, presence: true

  # When a task is completed, we remove it from the database.
  # This cannot be undone.
  def complete
    Task.find(id).destroy
  end
end
