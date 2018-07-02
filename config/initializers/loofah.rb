# Extend the list of acceptable CSS functions
# https://github.com/flavorjones/loofah/pull/123
Loofah::HTML5::WhiteList::ACCEPTABLE_CSS_FUNCTIONS.merge Set.new(%w[
  calc rgb rgba hsl hsla opacity
  rotate rotate3d rotateX rotateY rotateZ
  scale scale3d scaleX scaleY scaleZ
  translate translate3d translateX translateY translateZ
])
