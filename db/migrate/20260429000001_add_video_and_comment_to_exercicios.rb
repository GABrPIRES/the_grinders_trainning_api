class AddVideoAndCommentToExercicios < ActiveRecord::Migration[7.1]
  def change
    add_column :exercicios, :coach_comment, :text
    add_column :exercicios, :video_link, :text
  end
end
