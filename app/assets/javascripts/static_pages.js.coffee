# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#

updateCountdown = ->
  remaining = 140 - jQuery('#micropost_content').val().length
  jQuery('.countdown').text(remaining + ' characters remaining.')

jQuery(document).ready ($) ->
  updateCountdown()
  $('#micropost_content').live('input', updateCountdown)
