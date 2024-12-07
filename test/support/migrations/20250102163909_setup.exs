defmodule Klon.Repo.Migrations.Setup do
  use Ecto.Migration

  def change do
    create table(:implementeds) do
      add :value, :text
      timestamps()
    end

    create table(:unimplementeds) do
      add :value, :text
      timestamps()
    end

    create table(:normals) do
      add :value, :text
      add :variant, :text
      add :implemented_id, references(:implementeds)
      add :unimplemented_id, references(:unimplementeds)
      timestamps()
    end

    create index(:normals, [:implemented_id])
    create index(:normals, [:unimplemented_id])

    create table(:self_referentials) do
      add :value, :text
      add :implemented_id, references(:implementeds)
      add :unimplemented_id, references(:unimplementeds)
      add :parent_id, references(:self_referentials)
      timestamps()
    end

    create index(:self_referentials, [:implemented_id])
    create index(:self_referentials, [:unimplemented_id])
    create index(:self_referentials, [:parent_id])

    create table(:dependents) do
      add :value, :text
      add :normal_id, references(:normals), null: false
      add :self_referential_id, references(:self_referentials), null: false
      timestamps()
    end

    create index(:dependents, [:normal_id])
    create index(:dependents, [:self_referential_id])
  end
end
