UserGreeting = ->
  %h1 Welcome back!

GuestGreeting = ->
  %h1 Please sign up.

Greeting = ({isLoggedIn}) ->
  # return %UserGreeting if isLoggedIn
  if isLoggedIn
    %UserGreeting
  else
    %GuestGreeting

ReactDOM.render(
  %Greeting{ isLoggedIn: no }
  document.getElementById 'root'
)

LoginButton = ({onClick}) ->
  %button{ onClick } Login

LogoutButton = ({onClick}) ->
  %button{ onClick } Logout

class LoginControl extends React.Component
  constructor: (props) ->
    super props
    @state = isLoggedIn: no

  handleLoginClick: =>
    @setState isLoggedIn: yes

  handleLogoutClick: =>
    @setState isLoggedIn: no

  render: ->
    {isLoggedIn} = @state

    %div
      %Greeting{ isLoggedIn }
      = if isLoggedIn
        %LogoutButton( onClick={@handleLogoutClick} )
       else
        %LoginButton( onClick={@handleLoginClick} )
