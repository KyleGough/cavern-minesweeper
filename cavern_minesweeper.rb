#Single cell in the Minesweeper grid.
class Tile
  attr_accessor :adjacent, :tier, :btn, :revealed, :hiddenCount

  def initialize(btn)
   @btn = btn #Sets the contained button object in the cell.
   @tier = 0 #Tier indicates a cell that can be clicked on to reveal the adjacent count.
   @revealed = false #Cell has not yet been clicked on.
  end

end

#Generates the ores in the grid according to the difficulty.
def generateOres
  #For each tier populate the grid with that tier's ore.
  (0..@tiers-1).each do |tier|
    #Number of ores for the tier.
    oreCount = (@baseChance * (@nextTierChance**tier) * @rows * @columns).to_i #Calculates the number of ores for the tier based on the base chance and next tier chance.
    @oreTotal[tier] = oreCount
    @oreRemaining[tier] = oreCount
    @oreRemainingPara[tier].clear { para(@ore[tier].to_s + " " + @oreName[tier].to_s + "  ", strong("x" + @oreRemaining[tier].to_s), @style_orecount) } #Displays the remaining number of ores for the tier.
    @tierExp[tier] = oreCount * (2**tier) #Calculates the total experience aquired by mining all of the tier's ore.

    count = 0 #Number of ores added so far.
    #Randomly selects a cell on the grid to populate the ore with.
    while count < oreCount
      x = rand(@rows) #Selects a random row.
      y = rand(@columns) #Selects a random column.
      if (@tile[y][x].tier == 0) #Checks if the tile is empty.
        @tile[y][x].tier = tier + 1 #Applies the tier to the tile.
        count+=1 #New ore has been added.
      end
    end
  end
end

#Calculates the total tier number across adjacent tiles.
def calculateAdjacent
  #Loops through every tile in the grid.
  (0..@rows-1).each do |row|
    (0..@columns-1).each do |col|
      count = getTier(col+1, row+1) + getTier(col+1, row) + getTier(col+1, row-1)
      count += getTier(col, row+1) + getTier(col, row-1) + getTier(col-1, row+1)
      count += getTier(col-1, row) + getTier(col-1, row-1)
      @tile[col][row].adjacent = count #Totals the tier number in the adjacent tiles.
    end
   end
end

#Gets the tier value of the ore at the specific tile. If the tile is out of the grid returns 0.
def getTier(colIndex,rowIndex)
  if (colIndex > @columns-1 || colIndex < 0 || rowIndex > @rows-1 || rowIndex < 0)
    return 0 #Checks if the tile is in the bounds of the grid.
  else
    return @tile[colIndex][rowIndex].tier
  end
end

#Applies when the player clicks on a tile. Either shows the adjacent number or reveals the ore.
def mineTile(col, row)

  @endGame && return #Returns if the games has already been lost.
  @tile[col][row].revealed && return #Returns if the tile is already revealed.

  #Checks if the tile is not an ore.
  if (@tile[col][row].tier == 0)
    adjacent = @tile[col][row].adjacent

    if (adjacent == 0)
      floodFill(col,row) #If the tile has an adjacent value of 0, performs a flood fill to uncover the surrounding tiles.
    else
      @tile[col][row].revealed = true #Marks the tile as revealed.
      @hiddenCount-=1

      #Re-renders the button so it displays the new text.
      old = @tile[col][row].btn
      newStyle = old.style.dup
      old.parent.before(old) do
        @tile[col][row].btn = button adjacent.to_s, newStyle###
      end
      old.remove
    end
  else #Tile is an ore.
    @tile[col][row].revealed = true #Marks the tile as revealed.
    @hiddenCount -= 1
    tileTier = @tile[col][row].tier

    #Updates the experience
    @experienceInt += 2**(tileTier-1)
    @experience.clear { para("EXP: " + @experienceInt.to_s, @style_stats) }

    #Gets the amount of experience needed to reach the next tier.
    if (@tierInt < @tiers)
      if (@tierInt == @tiers - 1)
        required = 1 #If the player is on the penultimate tier then 100% of previous ores need to be uncovered.
      else
        #Interpolates the upper and lower bound to get the required percentage for the next tier.
        required = @expLowerBound +  (@tierInt * ((@expUpperBound - @expLowerBound) / @tiers))
      end


      #Gets the total amount of available experience for the player's current tier.
      expCount = 0
      (0..@tierInt-1).each do |tier|
        expCount += @tierExp[tier]
      end
      requiredExperience = (required * expCount).to_i

      #f the player's experience is greaster or equal to the required experience for the next tier, then the player advances a tier.
      if (@experienceInt >= requiredExperience)
        @tierInt+=1
        @tier.clear{ para("TIER: " + @tierInt.to_s, @style_stats) }
      end

    end

    #If the ore is a higher tier than the player's tier then the durability decreases depending on the difference in tier values.
    if (tileTier > @tierInt)
      @durabilityInt -= 2 * (tileTier - @tierInt)
      #If the durability is 0 or less then the player loses.
      if (@durabilityInt <= 0)
        @durabilityInt = 0
        @endState.clear { subtitle("You Lose!", @style_endgame) }
        @endGame = true
      end
      @durability.clear { para("DUR: " + @durabilityInt.to_s, @style_stats) }
    end

    #Updates the ore count for the mined ore.
    reduceOreCount(tileTier-1)

    #Re-renders the button to displays the ore.
    old = @tile[col][row].btn
    newStyle = old.style.dup
    old.parent.before(old) do
      @tile[col][row].btn = button(@ore[tileTier-1].to_s, newStyle)###
    end
    old.remove

  end

  #Checks if all tiles have been uncovered. If so gthe game was been won.
  if (@hiddenCount <= 0)
    @endState.clear { subtitle("You Win!", @style_endgame) }
    @endGame = true
  end

end

#Reduces the count of an ore by 1 and displays on screen.
def reduceOreCount(tier)
  @oreRemaining[tier]-=1
  @oreRemainingPara[tier].clear{ para(@ore[tier].to_s + " " + @oreName[tier].to_s + "  ", strong("x" + @oreRemaining[tier].to_s), @style_orecount) }
end

#Simple recursive flood fill to uncover tiles around tiles with an adjacent value of 0.
def floodFill(col, row)
  (col > @columns-1 || col < 0 || row > @rows-1 || row < 0) && return #Returns if the tile index is outside of the grid bounds.
  @tile[col][row].revealed && return #Returns if the tile is already revealed.

  @tile[col][row].revealed = true #Marks the tile as revealed.
  @hiddenCount -= 1
  adjacent = @tile[col][row].adjacent #Gets the adjacent count for the tile.

  #Reveal the adjacent count of the tile.
  old = @tile[col][row].btn
  newStyle = old.style.dup
  old.parent.before(old) do
    @btn = button(adjacent.to_s, newStyle)
  end
  old.remove

  #Recursively calls flood fill for the surrounding tiles.
  if (@tile[col][row].adjacent == 0)
    floodFill(col+1,row+1)
    floodFill(col+1,row)
    floodFill(col+1,row-1)
    floodFill(col,row+1)
    floodFill(col,row-1)
    floodFill(col-1,row+1)
    floodFill(col-1,row)
    floodFill(col-1,row-1)
  end

end

#Sets the grid and game variables for a new game.
def newGameSetup
  @experienceInt = 0 #Starting experience.
  @experience.clear { para("EXP: " + @experienceInt.to_s, @style_stats) }
  @tierInt = 1 #Starting tier.
  @tier.clear{ para("TIER: " + @tierInt.to_s, @style_stats) }
  @durability.clear { para("DUR: " + @durabilityInt.to_s, @style_stats) }

  @oreTotal = Array.new(@tiers, 0) #Total number of ores for each tier.
  @oreRemaining = Array.new(@tiers, 0) #Remaining number of ores for each tier.
  @tierExp = Array.new(@tiers) #Total experience available for each tier of ore.
  @tile = Array.new(@columns){Array.new(@rows)} #Declares the 2D array to represent the grid.
  @hiddenCount = @columns * @rows
  @endState.clear

  #Generates the grid of buttons
  @board.clear do
     stack(width: (@columns * @tile_size)) do
      background("#000000") #Sets the background to black.
      border("#CE8", strokewidth: 1)

      (0..@rows-1).each do |row|
        flow(width: 1.0) do
          (0..@columns-1).each do |col|
            @btn = button(width: @tile_size, height: @tile_size) {
              mineTile(col,row)
            }
            @tile[col][row] = Tile.new(@btn)
          end
        end
      end
    end
  end

  @endGame = false

  generateOres #Generates the ores into the grid.
  calculateAdjacent #Calculates all adjacent values of every tile.

end

#Resets the board and creates a new game.
def newGame(tiers = 5, expLowerBound = 0.25, expUpperBound = 0.93, durability = 10, baseChance = 0.065, nextTierChance = 0.7)
  #All intermediate next tier percentages are interpolated from the two bounds.
  @expUpperBound = expLowerBound #Upper bound percentage for percentage of available experience required to reach the final tier.
  @expLowerBound = expUpperBound #Lower bound percentage for percentage of available experience required to reach the next tier from the first tier.
  @tiers = tiers #Number of different ore tiers that appear in the grid.
  @durabilityInt = durability #Starting durability.
  @baseChance = baseChance #Level 1 type ore chance of appearing
  @nextTierChance = nextTierChance #E.G Level N chance = BASE CHANCE * NEXTTIERCHANCE^N-1

  newGameSetup #Sets up the grid and game variables.
end


Shoes.app(title: "Cavern Minesweeper", width: 1000, height: 600) {
  @rows = 15 #Number of rows on the board.
  @columns = 35 #Number of columns on the board.
  @tile_size = 22 #Pixel size of each tile.
  @tiers = 5 #Number of different ore tiers that appear in the grid.
  @oreRemainingPara = Array.new(@tiers)
  @ore = ["[1]", "[2]", "[3]", "[4]", "[5]"] #Text shown for each ore when uncovered.
  @oreName = ["Hematite", "Bauxite", "Cobaltite", "Cinnabar", "Uraninite"] #Name of each ore.

  @style_endgame = {stroke: white, align: "center", weight: "ultrabold", font: "California 36px"} #Style for the end game message.
  @style_orecount = {stroke: white, align: "center", font: "California 16px"} #Style for ore count display.
  @style_stats = {stroke: white, align: "center", weight: "ultrabold", font: "California 20px"} #Style for game stats.
  @style_title = {align: "center", stroke: white, font: "California 40px", margin_top: 20}

  background("#9D7544".."#1F160B") #Sets the background to a Brown->Black gradient.
  border("#CE8", strokewidth: 2) #Sets a small green border around the window.

  stack(margin: 8, margin_left: 120, width: 0.9) do
    background("#333333")
    title("Cavern Minesweeper", @style_title)

    flow do
      border("#CE8", strokewidth: 2)
      background("#333333")
      @tier = stack(margin_left: 0.05, width: 0.30)
      @experience = stack(width: 0.30)
      @durability = stack(width: 0.30)
    end

    stack do
      background("#333333")

      flow(width: 1.0) do
        @board = stack(width: (@columns * @tile_size)) #Placeholder for the grid of buttons
      end

      flow(margin: 3, width: 1.0) do
        (0..@tiers-1).each do |tier|
           @oreRemainingPara[tier] = stack(width: 150)
        end
      end
    end
  end

  @endState = flow(margin_left: 0.41, margin_right: 0.4, background: "#AAAAAA", align: "center")

  flow(margin_left: 120, width: 0.9, height: 40) do
    button("New Easy Game", width: 0.33) do
      newGame(5, 0.15, 0.80, 15, 0.055, 0.6)
    end
    button("New Normal Game", width: 0.33) do
      newGame
    end
    button("New Hard Game", width: 0.33) do
      newGame(5, 0.25, 0.98, 8, 0.075, 0.75)
    end
  end

  newGame #Starts the game on normal difficulty.

}
