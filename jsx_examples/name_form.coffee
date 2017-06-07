class NameForm extends React.Component
  constructor: (props) ->
    super props
    @state = value: ''

  onChange: ({target: {value}}) =>
    @setState {value}

  onSubmit: (event) =>
    alert "A name was submitted: #{@state.value}"
    event.preventDefault()

  render: ->
    {value} = @state

    %form{ @onSubmit }
      %label
        Name:
        %input{ type: 'text', value, @onChange }
      %input(
        type='submit'
        value='Submit'
      )
