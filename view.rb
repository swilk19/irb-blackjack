require 'control'

#Gather a list of player names given a number of players to gather.
def getPlayerNames(numplayers)
  names = Array.new()
  for num in 0...numplayers
    done = false
    #loop until i get valid input
    until done
      puts "Enter name for player #{num}."
      newplayer = gets.chomp!
      if(newplayer == nil || newplayer == "")
        puts "Please enter a valid name."
      else
        done = true
        names.push(newplayer)
      end
    end
  end
  return names
end

#loop over the list of players in the game, and collect bets
def doBets(game)
  done_players = Array.new()
  game.players.each do |player|
    #check if the player is broke
    if(player.money == 0)
      puts "#{player.name}, you're broke, and you're out!"
      done_players.push(player)
      if(done_players.size() == game.players.size())
        abort("No players left in the game. Game over!")
      end
      next
    end
    puts "#{player.name}, enter a bet for this round. You have $#{player.money}"
    done = false
    #loop until I get a valid bet
    until done
      betstring = gets.chomp!
      begin
        bet = Integer(betstring)
        done = player.placeBet(bet)
        raise ArgumentError if !done
      rescue ArgumentError
        puts "Please enter a valid bet. You have $#{player.money}"
      end
    end
  end
  game.removeBrokePlayers(done_players)
end

def doPlayerTurn(game)
  done = false
  #loop until the player's turn is complete
  until done
    #print the player object
    puts "Current player:"
    puts game.curplayer
    puts "Please enter your move (hit, stay, double down, split)"
    move = gets.chomp!
    case move
      when "hit"
        game.hit()
        if(game.curplayer.state == "bust")
          puts game.curplayer.hand
          puts "Bust!"
          done = true
        elsif(game.curplayer.state == "blackjack")
          puts game.curplayer.hand
          puts "Blackjack!"
          done = true
        end
      when "stay"
        #game.stay()
        done = true
      when "double down"
        #double down
        double = game.double_down()
        if(double)
          puts game.curplayer
          if(game.curplayer.state == "bust")
            puts "Bust!"
          elsif(game.curplayer.state == "blackjack")
            puts "Blackjack!"
          end
          done = true
        else
          puts "Can't double down right now."
        end
      when "split"
        #split
        split = game.split()
        if(split.instance_of? Player) #split successful
          prevPlayer = game.curplayer
          doPlayerTurn(game)
          game.curplayer = split
          doPlayerTurn(game)
          game.curplayer = prevPlayer
          done = true
        else
          puts "Can't split right now."
        end
      else
        puts "Please enter a valid move (hit, stay, double down, split)."
    end
  end
end

#do dealer's turn
def doDealerTurn(game)
  #turn the dealer's cards faceup
  game.turn_all_faceup()
  done = false
  until done
    puts game.curplayer
    #hit until score > 17
    if(game.curplayer.hand.score < 17)
      game.hit()
      if(game.curplayer.state == "bust")
        puts game.dealer.hand
        puts "Dealer busts!"
        done = true
      end
    else
      game.stay()
      done = true
    end
  end
end

#play a round of blackjack, including betting, and each players turn
def playRound(game)
  #do betting
  doBets(game)
  #deal some cards
  game.startRound()
  #do each players turn
  dealersTurn = false
  puts game
  until dealersTurn
    doPlayerTurn(game)
    game.nextTurn()
    if(game.curplayer == game.dealer)
      dealersTurn = true
    end
  end
  doDealerTurn(game)
  game.endRound()
  postRoundStats(game)
end

#print the post round stats of money
def postRoundStats(game)
  puts "Post round stats:"
  game.players.each do |player|
    puts "#{player.name} - #{player.state} - $#{player.money}"
  end
  puts "House - $#{game.dealer.money}"
end

puts "Welcome to blackjack! How many players?"
done = false
#verify that this is a valid number
game = nil
until done
  numplayers = gets.chomp!
  begin
    numplayersparsed = Integer(numplayers)
    if(numplayersparsed < 0 || numplayersparsed > 3)
      raise ArgumentError
    else
      done = true
      names = getPlayerNames(numplayersparsed)
      game = Game.new(names)
    end
  rescue ArgumentError
    puts "Invalid input, please enter a valid integer number between 1-3."
  end
end

#play a round of blackjack!
playRound(game)

#play more rounds until were done
done = false
until done
  puts "Play another round? yes/no"
  another = gets.chomp!
  case another
    when "yes"
      game.nextRound()
      playRound(game)
    when "no"
      done = true
    else
      puts "Plese enter yes or no."
  end
end