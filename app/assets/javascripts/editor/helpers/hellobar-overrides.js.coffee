HB.injectAtTop = (element) ->
  container = HB.$("#hellobar-preview-container")

  if container.children[0]
    container.insertBefore(element, container.children[0])
  else
    container.appendChild(element)
