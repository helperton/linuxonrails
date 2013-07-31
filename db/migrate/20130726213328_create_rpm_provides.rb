class CreateRpmProvides < ActiveRecord::Migration
  def change
    create_table :rpm_provides do |t|
      t.string :provides
      t.string :providedby

      t.timestamps
    end
    add_index(:rpm_provides, [:provides, :providedby])
  end
end
