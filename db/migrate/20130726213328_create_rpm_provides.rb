class CreateRpmProvides < ActiveRecord::Migration
  def change
    create_table :rpm_provides do |t|
      t.string :dependency
      t.string :providedby

      t.timestamps
    end
  end
end
