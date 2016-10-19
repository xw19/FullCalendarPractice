date_range_picker = ->
  $('.date-range-picker').each ->
    $(this).daterangepicker {
      timePicker: true
      timePickerIncrement: 30
      alwaysShowCalendars: true
    }, (start, end, label) ->
      $('.start_hidden').val start.format('YYYY-MM-DD HH:mm')
      $('.end_hidden').val end.format('YYYY-MM-DD HH:mm')

$(document).on 'turbolinks:load', date_range_picker
