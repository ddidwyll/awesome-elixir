defmodule ElixirAwesome.Repo.Migrations.Setup do
  use Ecto.Migration

  def change do
    create table(:categories, primary_key: false) do
      add :name, :string, primary_key: true
      add :description, :text
      add :exist, :boolean, default: false, null: false
    end

    create table(:projects, primary_key: false) do
      add :name, :string, null: false
      add :url, :string, primary_key: true
      add :stars_count, :integer, default: -1
      add :last_commit, :naive_datetime
      add :description, :text, null: false
      add :exist, :boolean, default: false, null: false

      add :category_name,
          references(:categories, type: :string, column: :name)
    end

    create index(:projects, [:stars_count])
    create index(:projects, [:exist])
    create index(:categories, [:exist])
  end
end
