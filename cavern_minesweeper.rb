Shoes.app {
  
  background "#AD7544".."#1F160B"
  border("#CE4", strokewidth: 3)
  
  
  
  stack(margin: 8) {
    
    title("Cavern Minesweeper",
          top: 20,
          align: "center",
          stroke: white)
           
    para "A Simple Minesweeper game created by Kyle Gough"
  
    @push = button("Click me!") {
      alert("Good job!")
    }
    
    @push.click {
      @output.replace("Clicked")
    }
    
    
    @output = para "Default"
    
    
    @rows = 15 #Number of rows on the board.
    @columns = 25 #Number of columns on the board.
    @tile_size = 20 #Pixel size of each tile.
    
    #Generates the grid of buttons
    (0..@rows).each do |row|
      flow do      
        (0..@columns).each do |col|
          button(width: @tile_size, height: @tile_size) {
            alert(row.to_s + " : " + col.to_s)
          }
        end      
      end
    end
    
    
    
 
  }
  
  
}
