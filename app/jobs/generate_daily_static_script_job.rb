class GenerateDailyStaticScriptJob < GenerateStaticScriptJob
  queue_as { "hb3_#{ Rails.env }_lowpriority" }
end
