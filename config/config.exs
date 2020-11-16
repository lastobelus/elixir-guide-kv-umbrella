# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

if Mix.env() == :prod do
  config :kv, :routing_table, [
    # later we will make the computer name configurable in `config/releases.ex`
    {?a..?m, :a_to_m@htulo},
    {?n..?z, :n_to_z@htulo}
  ]
else
  # this will run everything on the current node
  config :kv, :routing_table, [{?a..?z, node()}]
end
