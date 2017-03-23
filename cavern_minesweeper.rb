class Tile
  attr_accessor :adjacent, :tier, :btn, :revealed

  def initialize(btn)
   @btn = btn
   @tier = 0
   @revealed = false
  end

end

class Ore

  @@baseChance = 0.075 #Level 1 type ore chance of appearing
  @@nextTierChance = 0.75 #E.G Level 3 chance = 0.7 * 0.75^2

  def self.getChance(tier)
    return @@baseChance * (@@nextTierChance**tier)
  end

end

def generateOres
  #For each tier populate the grid with that tier's ore.
  (0..@tiers-1).each do |tier|

    #Number of ores for the tier.
    oreCount = (Ore.getChance(tier) * @rows * @columns).to_i
    @oreTotal[tier] = oreCount
    @oreRemaining[tier] = oreCount

    count = 0
    while count < oreCount
      x = rand(@rows)
      y = rand(@columns)

      if (@tile[y][x].tier == 0) #Checks if the tile is empty.
        @tile[y][x].tier = tier + 1
        count+=1
      end
    end
  end
end

#Calculates the total tier number across adjacent tiles.
def calculateAdjacent

  (0..@rows-1).each do |row|
    (0..@columns-1).each do |col|

      count = getTier(col+1, row+1) + getTier(col+1, row) + getTier(col+1, row-1)
      count += getTier(col, row+1) + getTier(col, row-1) + getTier(col-1, row+1)
      count += getTier(col-1, row) + getTier(col-1, row-1)
      @tile[col][row].adjacent = count

    end
   end
end

#Gts the tier value of the ore at the specific tile. If the tile is out of the grid returns 0.
def getTier(colIndex,rowIndex)
  if (colIndex > @columns-1 || colIndex < 0 || rowIndex > @rows-1 || rowIndex < 0)
    return 0
  else
    return @tile[colIndex][rowIndex].tier
  end
end


def mineTile(col, row)

  @tile[col][row].revealed && return #Returns if the tile is already revealed.

  if (@tile[col][row].tier == 0)
    adjacent = @tile[col][row].adjacent

    if (adjacent == 0)
      floodFill(col,row)
    else
      @tile[col][row].revealed = true
      old = @tile[col][row].btn
      newStyle = old.style.dup
      old.parent.before(old) do
        @tile[col][row].btn = button adjacent.to_s, newStyle###
      end
      old.remove
    end

  else

    @tile[col][row].revealed = true
    tileTier = @tile[col][row].tier

    #Updates the experience
    @experienceInt += 2**(tileTier-1)
    @experience.clear { para("EXP: " + @experienceInt.to_s, stroke: white, align: "center", weight: "ultrabold", font: "Pixel Cowboy Regular 8px") }

    #Gets the amount of experience needed to reach the next tier.
    if (@tierInt < @tiers)

      required = @expLowerBound +  (@tierInt * ((@expUpperBound - @expLowerBound) / @tiers)) #Percentage of available experience required for the next tier.
      expCount = 0

      (0..@tierInt).each do |tier|
        expCount+=@oreTotal[tier-1] * 2**(tier-1)
      end

      requiredExperience = (required * expCount).to_i
      if (@experienceInt >= requiredExperience)
        alert("Required Experience for tier #{@tierInt} : #{requiredExperience}")
        @tierInt+=1
        @tier.clear{ para("TIER: " + @tierInt.to_s, stroke: white, align: "center", weight: "ultrabold", font: "Pixel Cowboy Regular 10px") }
      end

    end

    if (tileTier > @tierInt)
      @durabilityInt -= 2**(tileTier - @tierInt)
      @durability.clear { para("DUR: " + @durabilityInt.to_s, stroke: white, align: "center", weight: "ultrabold", font: "Pixel Cowboy Regular 8px") }

      #if durability < 0
    end

    reduceOreCount(tileTier-1)

    #Updates the button
    old = @tile[col][row].btn
    newStyle = old.style.dup
    old.parent.before(old) do
      @tile[col][row].btn = button(@ore[tileTier-1].to_s, newStyle)###
    end
    old.remove

  end

end

def reduceOreCount(tier)
  @oreRemaining[tier]-=1
  @oreRemainingPara[tier].clear{ para(@ore[tier].to_s + " " + @oreName[tier].to_s + ": x" + @oreRemaining[tier].to_s, stroke: white) }
end

#Simple recursive flood fill.
def floodFill(col, row)

  return if (col > @columns-1 || col < 0 || row > @rows-1 || row < 0) #Checks if the tile index is within the grid bounds.
  @tile[col][row].revealed && return #Returns if the tile is already revealed.

  @tile[col][row].revealed = true #Mark tile as revealed.
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


#@levelProgress.fraction = 0.60
#animate do |i|
   #@levelProgress.fraction = (i % 100) / 100.0
#end


Shoes.app(title: "Cavern Minesweeper", width: 1000, height: 750) {

  @experienceInt = 0
  @tierInt = 1
  @durabilityInt = 20

  background("#AD7544".."#1F160B") #Sets the background to a Brown->Black gradient.
  border("#CE8", strokewidth: 2) #Sets a small green border around the window.

  stack(margin: 8) do

    title("Cavern Minesweeper", align: "center", stroke: white, font: "Pixel Cowboy Regular 26px")
    para("A Simple Minesweeper game created by Kyle Gough", align: "center", stroke: white, font: "Pixel Cowboy Regular 12px")


    @rows = 25 #Number of rows on the board.
    @columns = 25 #Number of columns on the board.
    @tile_size = 20 #Pixel size of each tile.
    @tiers = 5 #Number of different ore tiers that appear in the grid.

    #All intermediate next tier percentages are interpolated from the two bounds.
    @expUpperBound = 0.95 #Upper bound percentage for percentage of available experience required to reach the final tier.
    @expLowerBound = 0.30 #Lower bound percentage for percentage of available experience required to reach the next tier from the first tier.

    ###Increasing difficulty, more tiers, higher lower bound, high upper bound, increased nextTierChance and reduced durability.


    @oreTotal = Array.new(@tiers, 0)
    @oreRemaining = Array.new(@tiers, 0)
    @oreRemainingPara = Array.new(@tiers)

    @ore = ["░¹", "▒²", "▓³", "■4", "█5"]
    @oreName = ["Hematite", "Bauxite", "Cobaltite", "Cinnabar", "Uraninite"]

    @tile = Array.new(@columns){Array.new(@rows)} #Declares the 2D array to represent the grid.

    flow do
      @tier = stack(margin_left: 0.05, width: 0.30) do
        para("TIER: " + @tierInt.to_s, stroke: white, align: "center", weight: "ultrabold", font: "Pixel Cowboy Regular 10px")
      end
      @experience = stack(width: 0.30) do
        para("EXP: " + @experienceInt.to_s, stroke: white, align: "center", weight: "ultrabold", font: "Pixel Cowboy Regular 10px")
      end
      @durability = stack(width: 0.30) do
        para("DUR: " + @durabilityInt.to_s, stroke: white, align: "center", weight: "ultrabold", font: "Pixel Cowboy Regular 10px")
      end
    end

    @levelProgress = progress(margin_top: 15, margin_left: 61, margin_right: 61, width: 1.0, height: 25)

    #flow(margin_top: 20) do
      stack(width: 41) {}

      #Generates the grid of buttons
      stack(width: (@columns * @tile_size), height: (@rows * @tile_size)) do
        background("#000000") #Sets the background to black.
        border("#CE8", strokewidth: 1)

        (0..@rows-1).each do |row|
          flow do
            (0..@columns-1).each do |col|
              @btn = button(width: @tile_size, height: @tile_size) {
                mineTile(col,row)
              }
              @tile[col][row] = Tile.new(@btn)
            end
          end
        end
      end

       generateOres
       calculateAdjacent

       stack(width: 100) do
         (0..@tiers-1).each do |tier|
            @oreRemainingPara[tier] = flow do
              para(@ore[tier].to_s + " " + @oreName[tier].to_s + ": x" + @oreRemaining[tier].to_s, stroke: white)
            end
         end
       end




  end

}
