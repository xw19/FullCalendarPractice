# FullCalendar JS Practice

I tried to replicate this repo https://github.com/driftingruby/042-fullcalendar

## Explanation

These gems are used:

```ruby
gem 'bootstrap-sass'
gem 'fullcalendar-rails'
gem 'momentjs-rails'
gem 'simple_form'
```
Bootstrap sass adds Sass version of the bootstrap.
 fullcalendar-rails is a wrapper for [fullCalendar](https://fullcalendar.io/) . momentjs-rails is a js library for parsing, validating and displaying dates in JS. Simple form is alternative to form_for for rendering forms.

 Download [DateRangePicker](http://www.daterangepicker.com/), unzip the contents and place `daterangepicker.js` and `daterangepicker.scss` into vendor/assets/javascripts and vendor/assets/stylesheets respectively.

Run `bundle install`

and then initialize `simple_form` with

```ruby
rails generate simple_form:install --bootstrap
```
Now the setup is complete.

Now run the following

```ruby
rails g scaffold Event title:string start:datetime end:datetime color:string

rails g controller Visitors index
```

At this point you may need to make the application look good by adding some bootsra stylesheets and navbar add a file `_navbar.html` at `app/views/layouts`

In the application.html.erb also apply the Bootsrap markup suitably.

But you must add the following after `yield` in `application.html.erb`
```ruby
<div id='remote_container'></div>
```

This div provides the location for js to add html after ajax requests.

Open the `app/assets/javascripts/application.js` and add the following lines after require turbolinks

```js
//= require bootstrap-sprockets
//= require moment
//= require fullcalendar
//= require daterangepicker
```

These lines adds bootstrap, moment, fullcalendar and daterangepicker to sprocket pipeline

We will add then add root route by

```ruby
#config/routes.rb

  root 'visitors#index'
```

We will then add the following div to the `app/views/visitors/index.html.erb`

```html
  <div class='calendar'></div>
```

This div provides the place for our js to render the calendar.

To be able to properly select date we need a js method we write it at `app/assets/javascripts/date_range_picker.js`

```js
var date_range_picker;
date_range_picker = function() {
  $('.date-range-picker').each(function(){
    $(this).daterangepicker({
        timePicker: true,
        timePickerIncrement: 30,
        alwaysShowCalendars: true
    }, function(start, end, label) {
      $('.start_hidden').val(start.format('YYYY-MM-DD HH:mm'));
      $('.end_hidden').val(end.format('YYYY-MM-DD HH:mm'));
    });
  })
};
$(document).on('turbolinks:load', date_range_picker);
```

We will then write our js logic at `app/assets/javascripts/full_calendar.js`

inside the `full_calendar.js`

we first find all divs with calendar and loop through each of them.
at line#6 we modified the header of the calendar.

`selectable: true` will add callaback when select occurs. `selectHelper: true` will show a bar as we drag along the days. To make calendar ediable we add `editable: true`. Sometimes it can happen that in day there can be more than one event so to make sure it doesn't look bad we stack them using `evenLimit: true`. Last line of this file should contain `$(document).on('turbolinks:load', initialize_calendar);
` this line runs the js script after turbolinks load.

We then add a select callback which will fire when someone selects a day or days.
What it does is fetches a script from `/events/new` So we need to add change `events/new.js.erb` to:

```js
$('#remote_container').html('<%= j render "new" %>');
$('#new_event').modal('show');
```
The events model should lok like

```ruby
class Event < ApplicationRecord

  validates :title, presence: true

  attr_accessor :date_range

  def all_day_event?
    self.start == self.start.midnight && self.end == self.end.midnight ? true : false
  end
end
```

`events/_new.html.erb` to:

```html
<div class="modal fade" id="new_event">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h4 class="modal-title">Create New Event</h4>
      </div>
      <div class="modal-body">
        <%= render 'form', event: @event %>
      </div>
    </div>
  </div>
</div>
```
add this point you also need to modify the `events/_form.html.erb` to:

```html
<%= simple_form_for @event, remote: true do |f| %>
  <div class="form-inputs">
    <%= f.input :title %>
    <%= f.input :date_range, input_html: { class: "form-control input-sm date-range-picker" } %>
    <%= f.input_field :start, as: :hidden, value: Date.today, class: 'form-control input-sm start_hidden' %>
    <%= f.input_field :end, as: :hidden, value: Date.today, class: 'form-control input-sm end_hidden' %>
    <%= f.input :color, as: :select, collection: [['Black','black'], ['Green','green'], ['Red','red']] %>
  </div>

  <div class="form-actions">
    <%= f.button :submit %>
    <%= link_to 'Delete',
                event,
                method: :delete,
                class: 'btn btn-danger',
                data: { confirm: 'Are you sure?' },
                remote: true unless @event.new_record? %>
  </div>
<% end %>
```
Modify the `app/controllers/events_controller.rb` to look like this:

```ruby
class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  def index
    @events = Event.where(start: params[:start]..params[:end])
  end

  def show
  end

  def new
    @event = Event.new
  end

  def edit
  end

  def create
    @event = Event.new(event_params)
    @event.save
  end

  def update
    @event.update(event_params)
  end

  def destroy
    @event.destroy
  end

  private
    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:title, :date_range, :start, :end, :color)
    end
end
```
if you now open the application you can now add events.

Now similarly for changing the dates of various events we can add drag and drop to do this we need

```js
eventDrop: function(event, delta, revertFunc) {
  event_data = {
    event: {
      id: event.id,
      start: event.start.format(),
      end: event.end.format()
    }
  };
  $.ajax({
    url: event.update_url,
    data: event_data,
    type: 'PATCH'
  });
},

```
eventDrop callback accepts event params we then create a json of new values after we must need id, start and end and then fires a ajax call.

You maybe wondering where does the update_url has come from. Well we need to modify `app/views/events/`
to:

```js
date_format = event.all_day_event? ? '%Y-%m-%d' : '%Y-%m-%dT%H:%M:%S'

json.id event.id
json.title event.title
json.start event.start.strftime(date_format)
json.end event.end.strftime(date_format)

json.color event.color unless event.color.blank?
json.allDay event.all_day_event? ? true : false

json.update_url event_path(event, method: :patch)
json.edit_url edit_event_path(event)
```
Here we can see update_url is nohing but rails event_path

At this point we are able to reschedule the events but if we need to change them.

We need to add `events\edit.js.erb`

```js
$('#remote_container').html('<%= j render "edit" %>');
$('#edit_event').modal('show');
```

and `update.js.erb`

```js
$('#remote_container').html('<%= j render "edit" %>');
$('#edit_event').modal('show');
```

we also need to add our callback

```js
eventClick: function(event, delta, revertFunc) {
  $.getScript(event.edit_url, function() {
    $('#event_date_range').val(moment(event.start).format("MM/DD/YYYY HH:mm") + ' - ' + moment(event.end).format("MM/DD/YYYY HH:mm"))
    date_range_picker();
    $('.start_hidden').val(moment(event.start).format('YYYY-MM-DD HH:mm'));
    $('.end_hidden').val(moment(event.end).format('YYYY-MM-DD HH:mm'));
  });
}
```

We also need to add `_edit.html.erb`

```html
<div class="modal fade" id="edit_event">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h4 class="modal-title">Edit Event</h4>
      </div>
      <div class="modal-body">
        <%= render 'form', event: @event %>
      </div>
    </div>
  </div>
</div>
```

We can now update the events title and color.

We now need to be able to destroy it. When you click the sestroy buttons nothing happens. So
we need to add `events\destroy.js.erb`

```js
$('.calendar').fullCalendar('removeEvents', [<%= @event.id %>])
$('.modal').modal('hide');
```

At this pint most of our application is working. Last and final to better render the events modfy the
`index.json.jbuilder`

```json
son.array! @events do |event|
  date_format = event.all_day_event? ? '%Y-%m-%d' : '%Y-%m-%dT%H:%M:%S'
  json.id event.id
  json.title event.title
  json.start event.start.strftime(date_format)
  json.end event.end.strftime(date_format)
  json.color event.color unless event.color.blank?
  json.allDay event.all_day_event? ? true : false
  json.update_url event_path(event, method: :patch)
  json.edit_url edit_event_path(event)
end
```
