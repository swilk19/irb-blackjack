#Class that represents a single card.
class Card
	@@Faces = %w(Ace 2 3 4 5 6 7 8 9 10 Jack Queen King)
	@@Suits = %w(Clubs Spades Diamonds Hearts)

  attr_reader :suit, :face, :faceup
  attr_writer :suit, :face, :faceup

   #Constructor for the card class. Takes in a suit and a face.
	def initialize(face, suit, faceup=true)
    @suit = suit
    @face = face
    @faceup = faceup
  end

  #Return the static/constant array of predetermined faces
  def Card.Faces()
    @@Faces
  end

  #Return the predetermined static/constant array of predetermined suits
  def Card.Suits()
    @@Suits
  end

  def equals(card)
    if(@face == card.face)
      return true
    else
      return false
    end
  end

  #Override the to_s() method so I can print card objects.
	def to_s()
    return "#@face of #@suit" if @faceup
    return "Face Down Card" if !@faceup
	end
end

#Class that represents a deck of cards
class Deck

  attr_reader :cards, :cardsused

  #Method to initalize a deck, and shuffle it. Add support for using multiple decks, but use 1 by default.
  def initialize(numdecks = 1)
    #for each face, create a card of each suit, and add it to the list of cards
    @cards = Array.new()
    for num in 0..numdecks
      Card.Faces.each { |face| Card.Suits.each { |suit| @cards.push(Card.new(face, suit))}}
    end
    @cardsused = 0
    @cards.shuffle!
  end

  #Reshuffle the deck
  def shuffle()
    @cards.shuffle!
    @cardsused = 0
  end

  #Return the next card to be drawn from this deck
  #if no cards left, return false
  def drawCard(faceup = true)
    return false if cardsused > (@cards.length - 1) #this shouldn't really happen in a normal game but better to have it here in case
    card = @cards[cardsused]
    card.faceup = faceup
    @cardsused += 1
    return card
  end
end

#Object that represents a hand of cards.
class Hand

  attr_reader :cards, :score

  #create a new empty hand
  def initialize()
    @cards = Array.new()
  end

  #add a new card to this hand
  def addCard(new_card)
    @cards.push(new_card) if new_card.instance_of? Card #make sure i only add cards to the hand
    updateScore()
  end

  #Reset to an empty hand
  def resetHand()
    @cards = Array.new()
    @score = 0
  end

  #Calculate the score of this hand, by default don't calculate face down cards but in case the dealer has blackjack
  #on his opening hand, then we want to alert the rest of the game to that
  def updateScore(countFaceDown = false)
    #loop over the hand, if the card is a number card add its value
    #if the card is a face card add 10
    #if the card is an ace, do nothing but keep track of the number of aces.
    score = 0
    aces = 0
    #every card thats not an ace should be counted
    @cards.each do |card|
      if(card.faceup || countFaceDown)
        case card.face
          when "Jack","Queen","King" then score +=10
          when "Ace" then aces += 1
          else score += card.face.to_i
        end
      end
    end
    #Loop over the amount of aces and add them up to the score as well
    #puts "num aces: #{aces}"
    until aces == 0
      #this is for the case where you might have a 10 valued card, and an ace. this should be blackjack.
      if (score + 11 <= 21 && aces == 1)
        score += 11
      elsif(score + 11 < 21)
        score += 11
      else
        score += 1
      end
      aces -= 1
    end
    @score = score
  end

  #turn this hand into a string
  def to_s()
    result = ""
    @cards.each do |card|
      result = result + card.to_s + "\n"
    end
    result = result + "Score: #{score.to_s}"
    return result
  end
end

#Class that represents a player in the game
class Player
  #The default starting amount of money
  @@DefaultStartingCash = 1000

  attr_reader :curBet, :name, :hand, :money, :state, :split, :nummoves, :parent
  attr_writer :curBet, :hand, :money, :state, :nummoves, :parent, :split

  #Constructor for a player
  def initialize(name, startingcash = @@DefaultStartingCash)
    @hand = Hand.new()
    @money = startingcash
    @name = name
    @curBet = 0
    @state = "fine"
    @split = false
    @nummoves = 0
  end

  #Attempt to place a bet. If the bet is legal, return true. Otherwise, return false.
  def placeBet(amount)
    if(@money - amount >= 0)
      #Bet is allowed
      @curBet = amount
      @money -= amount
      return true
    else
      return false
    end
  end

  #Turn this player object into a readable string
  def to_s()
    return "#{name} - Bank: $#{money}\n" + @hand.to_s + " - Bet: $#{curBet}\n"
  end
end

#Class for a dealer
class Dealer

  attr_reader :hand, :money, :state
  attr_writer :money, :state

  #Constructor that initializes a dealer
  def initialize()
    @hand = Hand.new()
    @money = 0
  end

  #Turn the dealer into a string to be printed
  def to_s
    return "House - Currently with $#{money}\n" + @hand.to_s + "\n"
  end
end