$ = require './lib/zepto'

$ ->
  $('#save').on 'click', ->
    year  = $('#year').val()
    month = $('#month').val()
    day   = $('#day').val()

    date = "#{year}-#{month}-#{day}"

    alert date
