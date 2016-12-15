class ChangeOrganisations < ActiveRecord::Migration
  def change
    add_column :organisations, :timezone, :string, after: :code
  end
end
