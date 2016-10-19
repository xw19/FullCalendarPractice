initialize_calendar = ->
  $('.calendar').each ->
    calendar = $(this)
    calendar.fullCalendar
      schedulerLicenseKey: 'CC-Attribution-NonCommercial-NoDerivatives'
      defaultView: 'agendaDay'
      header:
        left: 'prev,next today'
        center: 'title'
        right: 'agendaDay,agendaTwoDay,agendaWeek,month'
      views: agendaTwoDay:
        type: 'agenda'
        duration: days: 2
        groupByResource: true
      selectable: true
      selectHelper: true
      editable: true
      eventLimit: true
      resources: '/resources.json'
      events: '/events.json'
      select: (start, end, jsEvent, view, resource) ->
        $.getScript '/events/new', ->
          $('#event_date_range').val moment(start).format('MM/DD/YYYY HH:mm') + ' - ' + moment(end).format('MM/DD/YYYY HH:mm')
          date_range_picker()
          $('#event_resource_id').val resource.id
          $('#event_start').val(moment(start).format('YYYY-MM-DD HH:mm'))
          $('#event_end').val(moment(end).format('YYYY-MM-DD HH:mm'))
        calendar.fullCalendar 'unselect'
      eventDrop: (event, delta, revertFunc) ->
        event_data = event:
          id: event.id
          start: event.start.format()
          end: event.end.format()
        $.ajax
          url: event.update_url
          data: event_data
          type: 'PATCH'

      eventClick: (event, delta, revertFunc) ->
        $.getScript event.edit_url, ->
          $('#event_date_range').val moment(event.start).format('MM/DD/YYYY HH:mm') + ' - ' + moment(event.end).format('MM/DD/YYYY HH:mm')
          date_range_picker()
          $('#event_resource_id').val event.resource.id
          $('.start_hidden').val moment(event.start).format('YYYY-MM-DD HH:mm')
          $('.end_hidden').val moment(event.end).format('YYYY-MM-DD HH:mm')

$(document).on 'turbolinks:load', initialize_calendar
