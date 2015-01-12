trackOptimizelyExperiments = ->
  if typeof(window['optimizely']) == "undefined"
    setTimeout(trackOptimizelyExperiments, 500)
  else
    variations = window['optimizely'].data.variations
    experiments = window['optimizely'].data.experiments

    for own key, value of window['optimizely'].data.state.variationMap
      experiment = experiments[key]
      variationId = experiment.variation_ids[value]
      variation = variations[variationId]

      InternalTracking.track_current_person("Optimizely: " + experiment.name, {variation: variation.name})

trackOptimizelyExperiments()
