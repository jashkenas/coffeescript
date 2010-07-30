# Examples from the Poignant Guide.

# ['toast', 'cheese', 'wine'].each { |food| print food.capitalize }

['toast', 'wine', 'cheese'].each (food) -> print food.capitalize()



# class LotteryTicket
#   def picks;           @picks;            end
#   def picks=(var);     @picks = var;      end
#   def purchased;       @purchased;        end
#   def purchased=(var); @purchased = var;  end
# end

LotteryTicket =
  get_picks:      -> @picks
  set_picks:      (@picks) ->
  get_purchased:  -> @purchase
  set_purchased:  (@purchased) ->



# class << LotteryDraw
#   def play
#     result = LotteryTicket.new_random
#     winners = {}
#     @@tickets.each do |buyer, ticket_list|
#       ticket_list.each do |ticket|
#         score = ticket.score( result )
#         next if score.zero?
#         winners[buyer] ||= []
#         winners[buyer] << [ ticket, score ]
#       end
#     end
#     @@tickets.clear
#     winners
#   end
# end

LotteryDraw =
  play: ->
    result  = LotteryTicket.new_random()
    winners = {}
    this.tickets.each (buyer, ticket_list) ->
      ticket_list.each (ticket) ->
        score = ticket.score result
        return if score is 0
        winners[buyer] or= []
        winners[buyer].push [ticket, score]
    this.tickets = {}
    winners



# module WishScanner
#   def scan_for_a_wish
#     wish = self.read.detect do |thought|
#       thought.index( 'wish: ' ) == 0
#     end
#     wish.gsub( 'wish: ', '' )
#   end
# end

WishScanner =
  scan_for_a_wish: ->
    wish = this.read().detect (thought) -> thought.index('wish: ') is 0
    wish.replace 'wish: ', ''



# class Creature
#
#   # This method applies a hit taken during a fight.
#   def hit( damage )
#     p_up = rand( charisma )
#     if p_up % 9 == 7
#       @life += p_up / 4
#       puts "[#{ self.class } magick powers up #{ p_up }!]"
#     end
#     @life -= damage
#     puts "[#{ self.class } has died.]" if @life <= 0
#   end
#
#   # This method takes one turn in a fight.
#   def fight( enemy, weapon )
#     if life <= 0
#       puts "[#{ self.class } is too dead to fight!]"
#       return
#     end
#
#     # Attack the opponent
#     your_hit = rand( strength + weapon )
#     puts "[You hit with #{ your_hit } points of damage!]"
#     enemy.hit( your_hit )
#
#     # Retaliation
#     p enemy
#     if enemy.life > 0
#       enemy_hit = rand( enemy.strength + enemy.weapon )
#       puts "[Your enemy hit with #{ enemy_hit } points of damage!]"
#       self.hit( enemy_hit )
#     end
#   end
#
# end

Creature =

  # This method applies a hit taken during a fight.
  hit: (damage) ->
    p_up = Math.rand this.charisma
    if p_up % 9 is 7
      this.life += p_up / 4
      puts "[" + this.name + " magick powers up " + p_up + "!]"
    this.life -= damage
    if this.life <= 0 then puts "[" + this.name + " has died.]"

  # This method takes one turn in a fight.
  fight: (enemy, weapon) ->
    if this.life <= 0 then return puts "[" + this.name + "is too dead to fight!]"

    # Attack the opponent.
    your_hit = Math.rand this.strength + weapon
    puts "[You hit with " + your_hit + "points of damage!]"
    enemy.hit your_hit

    # Retaliation.
    puts enemy
    if enemy.life > 0
      enemy_hit = Math.rand enemy.strength + enemy.weapon
      puts "[Your enemy hit with " + enemy_hit + "points of damage!]"
      this.hit enemy_hit



# # Get evil idea and swap in code words
# print "Enter your new idea: "
# idea = gets
# code_words.each do |real, code|
#   idea.gsub!( real, code )
# end
#
# # Save the jibberish to a new file
# print "File encoded.  Please enter a name for this idea: "
# idea_name = gets.strip
# File::open( "idea-" + idea_name + ".txt", "w" ) do |f|
#   f << idea
# end

# Get evil idea and swap in code words
print "Enter your new idea: "
idea = gets()
code_words.each (real, code) -> idea.replace(real, code)

# Save the jibberish to a new file
print "File encoded. Please enter a name for this idea: "
idea_name = gets().strip()
File.open "idea-" + idea_name + '.txt', 'w', (file) -> file.write idea



# def wipe_mutterings_from( sentence )
#   unless sentence.respond_to? :include?
#     raise ArgumentError,
#       "cannot wipe mutterings from a #{ sentence.class }"
#   end
#   while sentence.include? '('
#     open = sentence.index( '(' )
#     close = sentence.index( ')', open )
#     sentence[open..close] = '' if close
#   end
# end

wipe_mutterings_from = (sentence) ->
  throw new Error "cannot wipe mutterings" unless sentence.indexOf
  while sentence.indexOf('(') >= 0
    open     = sentence.indexOf('(') - 1
    close    = sentence.indexOf(')') + 1
    sentence = sentence[0..open] + sentence[close..sentence.length]
    sentence
