{:ok, _} = Klon.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Klon.Repo, :manual)
ExUnit.start()
