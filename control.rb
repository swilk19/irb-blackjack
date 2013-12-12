require 'model'

class Game

  attr_reader :players, :dealer, :deck, :curplayer
  attr_writer :curplayer

  #start a game
  def initialize(names)
    @players = Array.new()
    for num in 0...names.length
      newplayer = Player.new(names[num])
      @players.push(newplayer)
      @curplayer ||= newplayer
    end
    @dealer = Dealer.new()
    @deck = Deck.new()
    @nummoves=0
  end

  #double down with the current player. return false if cant be done.
  def double_down()
    if(@curplayer.nummoves > 0)
      return false
    end
    if(@curplayer.money - @curplayer.curBet >= 0)
      money = @curplayer.curBet
      @curplayer.curBet += money
      @curplayer.money -= money
      hit()
      return true
    else
      return false
    end
  end

  #perform a split as the players move
  def split()
    if(@curplayer.nummoves > 0)
      return false
    end
    #check their 2 cards, if theyre the same, split cur players hand into a 2 dimensional array of hands.
    if(@curplayer.hand.cards[0].equals(@curplayer.hand.cards[1]))
      #two cards are the same
      #split is allowed
      splitplayer = Player.new(@curplayer.name, @curplayer.money)
      splitbet = @curplayer.curBet/2
      #split the bet in half and give it to the new player
      splitplayer.curBet = splitbet
      #subtract split bet from current bet
      @curplayer.curBet = @curplayer.curBet - splitbet
      #take one of the cards and give it to the new player
      splitplayer.hand.addCard(@curplayer.hand.cards.pop())
      #update the scores of both hands
      splitplayer.hand.updateScore()
      @curplayer.hand.updateScore()
      splitplayer.state = "fine"
      #set the parent pointer so that I can take any winnings and give it to them
      splitplayer.parent = @curplayer
      splitplayer.split = true
      @players.push(splitplayer)
      #set number of moves to 1 so that they cant split again/double down
      @curplayer.nummoves += 1
      splitplayer.nummoves +=1
      return splitplayer
    else
      return false
    end
  end


  def hit()
    #increment number of moves made if this is a player that is hitting
    @curplayer.nummoves += 1 if @curplayer.instance_of? Player
    #Draw a card face up from the deck
    newcard = @deck.drawCard()
    #add it to that players hand
    @curplayer.hand.addCard(newcard)
    #get the score of the hand
    score = @curplayer.hand.score()
    #update the state after a hit
    if(score > 21)
      @curplayer.state = "bust"
    elsif(score == 21)
      @curplayer.state = "blackjack"
    else
      @curplayer.state = "fine"
    end
    @nummoves += 1
  end

  #increment to the next player's turn
  def nextTurn()
    index = @players.index(@curplayer)
    puts "index = #{index}"
    if(index == nil)
      #this is probably the dealer
      return
    end
    if(index == @players.size - 1) #This is the last player
      @curplayer = @dealer #its now the dealer's turn
    else #not last persons turn yet
      index += 1 #get the next index
      if(@players[index].split)
        @curplayer = @dealer 
      else
        @curplayer = @players[index] #set the current player to the next one
      end
    end
    @nummoves = 0
  end

  #go through at the end of a round and determine winners and losers based on state
  def getFinalState()
    dealer_score = @dealer.hand.score
    case @dealer.state
      when "bust"
        #every player that didnt bust wins
        @players.each do |player|
          if(player.state != "bust")
            player.state = "won"
          else
            player.state = "lose"
          end
        end
      when "fine"
        #everyone with a lower score than the dealer loses, everyone with a higher score that didnt bust wins
        @players.each do |player|
          if(player.state == "bust")
            player.state = "lose"
          elsif(player.hand.score < dealer_score)
            player.state = "lose"
          elsif(player.hand.score > dealer_score)
            player.state = "won"
          else
            player.state = "push"
          end
        end
      when "blackjack"
        #everyone lower score loses, everyone equal score pushes
        @players.each do |player|
          if(player.hand.score == dealer_score)
            player.state = "push"
          else
            player.state = "lose"
          end
        end
    end
  end

  def handleBets()
    #go through each player and dish out the money based on state
    @players.each do |player|
      case player.state
        when "won"
          @dealer.money -= player.curBet
          #give them back their bet*2 (because i subtract their bet from their total when they make it, they earn it back plus what they bet)
          winnings = player.curBet * 2
          player.curBet = 0
          if(player.split)
            player.parent.money += winnings
          else
            player.money += winnings
          end
        when "lose"
          #give their money to the dealer, why not keep track of how much he makes?
          @dealer.money += player.curBet
          #set their current bet to 0
          player.curBet = 0
        when "push"
          #give them back their bet
          winnings = player.curBet
          player.curBet = 0
          if(player.split)
            player.parent.money += winnings
          else
            player.money += winnings
          end
        end
    end
  end

  def startRound()
    #deal 2 cards to each player, one face down to the dealer
    @players.each do |player|
      firstCard = @deck.drawCard()
      secondCard = @deck.drawCard()
      player.hand.addCard(firstCard)
      player.hand.addCard(secondCard)
    end
    faceUpCard = @deck.drawCard()
    @dealer.hand.addCard(faceUpCard)
    faceDownCard = @deck.drawCard(false)
    @dealer.hand.addCard(faceDownCard)
    @dealer.hand.updateScore(true)
    if(@dealer.hand.score == 21)
      faceDownCard.faceup = true
      @dealer.state = "blackjack"
    else
      @dealer.hand.updateScore()
    end
  end

  #turn all cards face up in the dealer's hand
  def turn_all_faceup()
    @dealer.hand.cards.each do |card|
      card.faceup = true
    end
  end

  #reset everyone's state back to fine if they still have money
  def resetStates()
    @players.each do |player|
      if(player.money > 0)
        player.state = "fine"
      else
        player.state = "broke"
      end
    end
  end

  def endRound()
    #Go around, deal with everyones bets
    getFinalState()
    handleBets()
    #reset everyones hand
    @players.each do |player|
      player.hand.resetHand()
      player.nummoves = 0
    end
    @dealer.hand.resetHand()
    #reset current player to player 0
    @curplayer = @players[0]
    removeSplitPlayers()
  end


  def nextRound()
    #set the current player to index 0
    @curplayer = @players[0]
    resetStates()
    #shuffle the deck, empty everyones hand
    @players.each do |player|
      player.hand.resetHand()
    end
    @dealer.hand.resetHand()
    @deck.shuffle()
  end

  def get_num_players()
    return @players.length
  end

  def removeBrokePlayers(done_players)
    done_players.each do |done_player|
      remove_player(done_player)
    end
    @curplayer = @players[0]
  end

  def removeSplitPlayers()
    @players.each do |player|
      if(player.split)
        remove_player(player)
      end
    end
  end

  def remove_player(player)
    @players.delete(player)
  end

  def to_s()
    game_string = "Current game board: \n"
    @players.each do |player|
      game_string = game_string + " " + player.to_s + "\n\n"
    end
    game_string = game_string + " " + dealer.to_s + "\n\n"
    return game_string
  end

end
