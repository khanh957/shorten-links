class CreateShortLinksTable < ActiveRecord::Migration[7.0]
  def change
    create_table :short_urls do |t|
      t.string :short_code, null: false, index: { unique: true }
      t.string :original_url, null: false
      t.datetime :expired_at, null: true
      t.timestamps
    end
  end
end
