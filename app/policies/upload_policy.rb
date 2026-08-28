class UploadPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(user: user)
  end

  def show?    = record.user == user
  def create?  = true
  def update?  = record.user == user
  def destroy? = record.user == user

  # named aliases so controllers read clearly
  def add_words?       = update?
  def start_adventure? = update? && record.saved_words.any?
end
