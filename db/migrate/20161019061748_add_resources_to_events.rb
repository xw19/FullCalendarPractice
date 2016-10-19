class AddResourcesToEvents < ActiveRecord::Migration[5.0]
  def change
    add_reference :events, :resource, foreign_key: true
  end
end
