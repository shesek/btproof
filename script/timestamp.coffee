{ SHA256, RIPEMD160, lib: { WordArray }, enc: { Hex } } = CryptoJS
{ Base58 } = Bitcoin

VERSION_BYTE = '00'

data_to_address = (data) -> hash_to_address SHA256 data
hash_to_address = (hash) ->
  hash = Hex.parse VERSION_BYTE + RIPEMD160 hash
  checksum = (SHA256 SHA256 hash).toString().substr(0,8)
  Base58.encode hex_to_byte_array hash + checksum

hex_to_byte_array = (str) -> parseInt (str.substr i*2, 2), 16 for i in [0...(str.length/2)]
is_valid_hash = (str) -> str.length and (str.length%2) is 0 and not str.match /[^a-f0-9]/

get_address = do (
  handle_text = (cb) ->
    data = $('#text textarea').val()
    return display_error 'Text field is empty.' unless data.length
    cb data_to_address data
  handle_file = (cb) ->
    file = $('#file input')[0].files[0]
    return display_error 'No file selected.' unless file?
    reader = new FileReader
    reader.onload = -> cb data_to_address WordArray.create reader.result
    reader.readAsArrayBuffer file
  handle_hash = (cb) ->
    hash = $('#hash input').val()
    return display_error 'Invalid hash. Should be in hexdecimal form.' unless is_valid_hash hash
    cb hash_to_address Hex.parse hash
) -> (cb) -> switch
  when $('#text').is ':visible' then handle_text cb
  when $('#file').is ':visible' then handle_file cb
  when $('#hash').is ':visible' then handle_hash cb
  else display_error 'Cannot detect data to timestamp.'

first_seen = (address, cb) ->
  ($.get "https://blockchain.info/q/addressfirstseen/#{address}").always (resp, status) ->
    cb (new Date resp*1000 if status is 'success' and resp>0)

display_error = (message) ->
  if message then $('.timestamp .error').text(message).show()
  else $('.timestamp .error').hide()

unless window.FileReader
  $('#file').addClass('alert alert-error')
    .text 'Your browser doesn\'t support the FileReader API, which is used to
           hash the file on your browser without uploading it. Please switch
           to a newer browser or hash the file locally.'

# Buttons
$('#pay').click ->
  get_address (address) ->
    display_error false
    $('#result').show().text 'Address: ' + address
    document.location = 'bitcoin:' + address + '?amount=0.00000001'

$('#check-timestamp').click ->
  get_address (address) ->
    display_error false
    first_seen address, (timestamp) ->
      $('#result').show().text if timestamp then "#{address} exists since #{timestamp}" \
                                            else "#{address} was never seen on the blockchain"

$('#no-bitcoins').click ->
  get_address (address) => document.location = "#{$(this).data('url')}##{address}"

# Init
$('[data-toggle=tooltip]').tooltip()
$('#text textarea').focus()
