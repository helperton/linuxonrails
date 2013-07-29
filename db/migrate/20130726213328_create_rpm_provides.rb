class CreateRpmProvides < ActiveRecord::Migration
  def change
    create_table :rpm_provides do |t|
      t.string :provides
      t.string :version
      t.string :providedby
      t.string :arch
      t.string :rpm

      t.timestamps
    end
  end
end
