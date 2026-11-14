import 'dart:convert';
import 'dart:typed_data';

/// The photo the S02 examples show: a sunrise over hills, 96 by 64 pixels,
/// as a PNG held in the code. The examples are about what an `Image` tells
/// assistive technology, which is the same for `Image.asset`,
/// `Image.network`, and `Image.memory`; holding the bytes here keeps the
/// examples working in the app and in the Widgetbook without an asset path.
final Uint8List sunrisePng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAGAAAABACAIAAABqVuVZAAACEklEQVR42u3Se0uTYRzG'
  '8evV9Br6s78iCIRACIIggkAIpCPaMlceamkqszEbHtLJ0tQ8ZK7sgCQVEgRBIAS9l3pg'
  'IGNz1577HvfviXHBZ4yN3Q/X/WU43XsgBM7c+SYEzqa+CIGOu/tC4Ny9z0Kgs39PCJxP'
  'fxICF+5/EAIXB94LgUuD74TA5aGyELgyvCMEuh5tC4GrmS0h0P14QwhcH1kXAreerAmB'
  'nrEVIZAafykE+iaWhEA6WxICA5OLQmD4aVEIZHLzQmA0PycExqdmhUD22bQQyBUKQiA/'
  'PSUECjN5ITAzmxMCz+cmk/X38BSX7DwU57NJaZqmWlIjUVqYSIRTnYpEdmK5OGbPo06F'
  '/VSsLo4ai+55ovPkEddGxmuxXhqxVFPHL5PlYGy+yJhpVMfjfxRoYc2q6BtsLz0006iO'
  'RyOzeSgvD9ngdTwa2czD7sqgjTiBnBrZbMPH1QcGYtZxamQzD3tr6dCc6sQPZDMP+6/6'
  'Q3MNFLORzTZ83egLyqNOzEY283CwmQrHu07TRjW/DDcP37d644sOuP6+daRLDadtMefh'
  'x+uepo496XcqtDjXcZqH6PXzze1Gmp73PhgOuY7HPFTefu3crBf/KX6nwjn2On4jUf3h'
  'sHyj4n+4ZIuO7lLP6TlogxaN/H57rZ7rQ9o5UOTPbnc1jye0eaDWKZACKZACKZACKZAC'
  'KZAokI9/2Pl1U5nHDqMAAAAASUVORK5CYII=',
);
