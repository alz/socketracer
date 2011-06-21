# Deals with browser compatibility
  
exports.isSupported = ->
  $.browser.safari is true or $.browser.webkit is true or ($.browser.mozilla is true and parseInt($.browser.version) is 2) 

exports.showIncompatibleMessage = ->
  $('.views').hide()
  $('#browserNotSupported').show()