@ReactMoneySmart2Input = createReactClass(
  componentDidMount: ->

  getInitialState: ->
    return {
      value: @props.value,
      prev_value: @props.value,
      prev_pos: 0,
    }

  generate_value: (old_val, pos, key) ->
    next_char = old_val[pos]
    prev_char = old_val[pos-1]
    value = parseFloat(old_val.replace(',', '.'))
    is_value_zero = (!old_val.length || value == 0)
    in_decimal = (old_val.indexOf(',') < pos)
    is_digital_key = /^[0-9]$/.test(key)
    is_decimal_key = /^[\,\.\ \=\+\-]$/.test(key)
    decimal_pos = old_val.indexOf(',')

    if key == 'Delete' && /^[\,\.]$/.test(next_char)
      return { val: old_val, pos: pos } # don`t delete decimal symbol
    else if key == 'Backspace' && pos > 0
      if prev_char == ','
        return { val: old_val, pos: pos - 1 } # don`t delete decimal symbol
      else if next_char == ',' || in_decimal
        new_val = old_val.slice(0, pos-1) + '0' + old_val.slice(pos)
        return { val: new_val, pos: pos - 1 } # replace by '0'
      else
        new_val = old_val.slice(0, pos-1) + old_val.slice(pos)
        return { val: new_val, pos: pos - 1 } # replace by '0'

    else if key.length > 1
      # if press control key (like arrows or 'home')
      return null # behavior without changes

    else if !is_digital_key && !is_decimal_key
      # if press symbol (not control) key (like 'b' or '@')
      return { val: old_val, pos: pos } # ignore key

    else if pos == 0 && next_char == '0' && is_digital_key
      return { val: "#{key},00", pos: 1 }

    else if !in_decimal && is_digital_key
      return null # just paste new symbol in custom way

    else if (next_char == ',' || decimal_pos == -1) && is_decimal_key
      return { val: old_val, pos: pos + 1 } # shift cursor right

    else if !in_decimal && is_decimal_key
      return { val: old_val, pos: pos } # ignore key

    else if in_decimal && (pos - decimal_pos > 2)
      return { val: old_val, pos: pos } # ignore key

    else if in_decimal && is_decimal_key
      return { val: old_val, pos: pos } # ignore key

    else if in_decimal && is_digital_key
      # replace digital in decimal part of value
      new_val = old_val.slice(0, pos) + key + old_val.slice(pos+1)
      return { val: new_val, pos: pos + 1 }

  # just for tests on mobiles
  logger: (event) ->
    type = event.type
    which = event.which
    key = event.key
    keyCode = event.keyCode
    charCode = event.charCode
    old_pos = event.target.selectionStart
    input_value = event.target.value
    keyIdentifier = event.keyIdentifier
    code = event.code

    hash = JSON.stringify { input_value, keyIdentifier, code, which, key, keyCode, charCode, old_pos, type }
    # $('.console').append("<div>#{hash}</div")

  get_key_by_diff: (old_value, new_value) ->
    return if old_value == undefined || new_value == undefined
    return unless old_value.length && new_value.length
    for ch, i in new_value
      return ch if old_value[i] != new_value[i]

  try_change_value: (event) ->
    return if @state.prev_value == null || @state.prev_value == undefined
    key = @get_key_by_diff(@state.prev_value, event.target.value)
    return if key == null || key == undefined
    @change_value(event, key)

  change_value: (event, key) ->
    old_pos = @state.prev_pos
    old_val = @state.prev_value || event.target.value

    value_hash = @generate_value(old_val, old_pos, key)
    if value_hash
      new_val = value_hash['val']
      new_pos = value_hash['pos']

      event.target.value = new_val
      event.target.setSelectionRange(new_pos, new_pos)
      event.preventDefault()
    @state.prev_value = null

  oninput: (event) ->
    @logger event
    @try_change_value(event)

  onkeyup: (event) ->
    @logger event
    @state.prev_value = null

  onkeypress: (event) ->
    @logger event
    @state.prev_pos = event.target.selectionStart
    if event.which == 229
      @state.prev_value = event.target.value

  onkeydown: (event) ->
    @logger event

    return if @state.prev_value =='Control' || @state.prev_value == 'Alt'
    @state.prev_value = null
    @state.prev_pos = event.target.selectionStart
    if event.key == 'Control' || event.key == 'Alt'
      @state.prev_value = event.key
    else if event.which != 229
      @change_value(event, event.key)
    else
      @state.prev_value = event.target.value


  onchange: (event) ->
    value = event.target.value
    value = '0,00' if !value.length
    value = value.replace(/[^0-9\,]/, '')
    while value.match(/\,/g).length > 1
      value = value.replace(/\,/, '') # delete dublicate decimals
    value = value + ',00' unless /[\,\.]/.test(value)
    @setState { value: value }

  onblur: (event) ->
    value = parseFloat(event.target.value.replace(',', '.'))
    if !value || value == 0
      @setState { value: '0,00' }


  onclick: (event) ->
    value = event.target.value.replace(',', '.')
    if value == '' || parseFloat(value) == 0
      event.target.setSelectionRange(0, 0)

  render: ->
    input_params =
      className: 'react_money_input form-control',
      pattern: @props.pattern,
      onKeyDown: @onkeydown,
      onKeyUp: @onkeyup,
      onKeyPress: @onkeypress,
      onChange: @onchange,
      onInput: @oninput,
      onBlur: @onblur,
      onClick: @onclick,
      value: @state.value,

    if @props.type == 'auto'
      if navigator.userAgent.match(/(iPad|iPhone|iPod)/g)
        input_params['type'] = 'text'
      else
        input_params['type'] = 'tel'
    else
      input_params['type'] = @props.type || 'text'

    React.createElement('div', { className: 'form-group' },
      React.createElement('div', { className: 'input-group' },
        React.createElement('span', { className: 'input-group-addon' }, '€'),
        React.createElement('input', input_params, null),
      )
    )
)