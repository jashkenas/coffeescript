Mailbox = ({unreadMessages: {length}}) ->
  %div
    %h1 Hello!
    = length and
      %h2 You have {length} unread messages.
    = if length
      %h2 You have {length} unread messages.
