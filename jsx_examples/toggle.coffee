class Toggle extends React.Component
  constructor: (props) ->
    super props
    @state = isToggleOn: yes

  handleClick: =>
    @setState (prevState) ->
      isToggleOn: not prevState.isToggleOn

  render: ->
    %button{ onClick: @handleClick }
      = if @state.isToggleOn
          'ON'
        else
          'OFF'

#ReactDOM.render %Toggle,
ReactDOM.render(
  %Toggle
  document.getElementById 'root'
)
