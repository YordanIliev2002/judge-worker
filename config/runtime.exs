import Config

config :judge_worker, Rabbit,
  username: System.get_env("AMQP_USERNAME") || "admin",
  password: System.get_env("AMQP_PASSWORD") || "password"
