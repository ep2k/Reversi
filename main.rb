require 'matrix'

# 定数
X = 0; Y = 1
B = "●"; W = "○"
Arround = [[-1,-1],[0,-1],[1,-1],[-1,0],[1,0],[-1,1],[0,1],[1,1]]

class Board
  
  attr_accessor :turn
  attr_reader :stone
  attr_reader :black
  attr_reader :white
  attr_reader :board_arr
  def initialize
    @turn = 1 # 現在の手番(1:先手,-1:後手)
    @stone = 4 # 全石の数
    @black = 2 # 黒の数
    @white = 2 # 白の数

    # ボード配列
    @board_arr = Array.new(8) do Array.new(8,0) end
    @board_arr[3][3] = -1
    @board_arr[3][4] = 1
    @board_arr[4][3] = 1
    @board_arr[4][4] = -1
    
    # 現在存在する石の周囲のマス
    @arround = [[2,2],[3,2],[4,2],[5,2],[2,3],[5,3],[2,4],[5,4],[2,5],[3,5],[4,5],[5,5]]

  end
  def move(hand) # 指し手を与えた結果の盤面を返す,違法手であった場合のことは考慮していない(Human,CPUクラス内で防ぐ)
    @board_arr[hand[Y]][hand[X]] = @turn
    
    # 8方向のチェック
    8.times do |i|
      x = hand[X]+Arround[i][X]; y = hand[Y]+Arround[i][Y]
      count = 0
      while true
        if @board_arr[y] == nil
          count = 0
          break
        end
        case @board_arr[y][x]
        when @turn then
          break
        when 0 then
          count = 0
          break
        when nil then
          count = 0
          break
        end
        count += 1
        x += Arround[i][X]; y += Arround[i][Y]
      end
      #puts(count)
      count.times do |j|
        puts(hand[Y]+j*Arround[i][Y],hand[X]+j*Arround[i][X])
        board_arr[hand[Y]+(j+1)*Arround[i][Y]][hand[X]+(j+1)*Arround[i][X]] = @turn
      end
    end
    self.update_arround(hand)
    @stone += 1
    @turn == 1 ? @black += 1 : @white += 1
    @turn *= -1
  end
  def check(hand) # 指し手が合法手であるか判定しtrue/falseを返す
    # moveメソッドのうち、必要のない処理を省略した
    unless @board_arr[hand[Y]][hand[X]] == 0
      return false
    end
    8.times do |i|
      x = hand[X]+Arround[i][X]; y = hand[Y]+Arround[i][Y]
      count = 0
      while true
        if board_arr[y] == nil
          count = 0
          break
        end
        case board_arr[y][x]
        when turn then
          break
        when 0 then
          count = 0
          break
        when nil then
          count = 0
          break
        end
        count += 1
        x += Arround[i][X]; y += Arround[i][Y]
      end
      if count > 0 then return true end
    end
    return false
  end
  def generate # 合法手の配列を返す
    return [1,9] #########
  end
  def update_arround(move) # @arroundの更新
    @arround.delete(move)
    8.times do |i|
      tmp = [move[X] + Arround[i][X], move[Y] + Arround[i][Y]]
      if @board_arr == 0 then @arround.push(move).uniq! end
    end
  end
  def win_player
    if black > white
      return 1
    elsif black < white
      return -1
    else
      return 0
    end
  end
end

class Human
  attr_reader :name
  def initialize(mode) # mode: 1,2 対人間/ -1,-2 対CPU
    @name = mode>0 ? "#{mode}P" : "You" # 表示名
    @turn = mode.abs == 1 ? 1 : -1 # 1:先手,-1:後手
  end
  def move(board) # 指し手を選択させる
    print(@name + " : Please choose your hand.(right, down) ex. 4 5\n> ")
    while(true) # 正しい座標を入力するまで繰り返す
      hand_input = gets.chomp
      hand = [hand_input[0].to_i - 1, hand_input[2].to_i - 1]
      if ((hand[0] < 0) || (hand[0]) > 8 || (hand[1] < 0) || (hand[1] > 8)) # 盤外
        print("\nPlease input correct position!\n> ")
        next
      elsif !board.check(hand) # 合法手でない
        print("\nYou can't put it there.\n> ")
        next
      end
      break
    end
    return hand
  end

end

class CPU
  attr_reader :name
  def initialize(turn,try_times) # turnは1なら先手
    @name = "CPU" + try_times.to_s
    @turn = turn
    @try_times = try_times
  end
  def move(board) # 指し手を決定し返す

  end
end

class Game
  def initialize
    @mainboard = Board.new
    self.start # 先後のプレイヤー及びモンテカルロの試行回数の設定
    self.play
  end
  def start
    print("\n//// Reversi //////\n\n")
    print("Please choose(0~2).\n0:Human vs Human\n1:Human vs CPU\n2:CPU vs CPU\n> ")
    mode = gets.chomp
    print("\n")
    case mode.to_i
    when 0 then
      @black_player = Human.new(1)
      @white_player = Human.new(2)
    when 1 then
      print("You are first? Yes(0)/No(1)/Random(2)\n> ")
      tmp = gets.chomp
      print("\nCPU's try times(natural number)?\n> ")
      try_times = gets.chomp
      if tmp == 2 then tmp = rand(2) end
      if tmp == 0
        @black_player = Human.new(-1)
        @white_player = CPU.new(false,try_times)
      else
        @black_player = CPU.new(true,try_times)
        @white_player = Human.new(-2)
      end
    when 2 then
      print("1st CPU's try times(natural number)?\n> ")
      first_try = gets.chomp
      print("\n2nd CPU's try times(natural number)?\n> ")
      second_try = gets.chomp
      @black_player = CPU.new(true,first_try)
      @white_player = CPU.new(false,second_try)
    end
  end
  def play
    until(@mainboard.stone == 64)
      self.display_board
      if @mainboard.generate.length == 0
        if endflg
          break
        else
          endfig = true
          @mainboard.turn *= -1
          next
        end
      end
      if @mainboard.turn == 1
        @mainboard.move(@black_player.move(@mainboard))
      else
        @mainboard.move(@white_player.move(@mainboard))
      end
    end
    print("\n\n")
    case @mainboard.win_player
    when 0 then
      print("Draw")
    when 1 then
      print(@black_player.name + " win!")
    when -1 then
      print(@white_player.name + " win!")
    end
    print(" (#{@mainboard.black}-#{@mainboard.white})\n\n")
  end
  def display_board
    vert = "  --- --- --- --- --- --- --- ---"
    print("\n   1   2   3   4   5   6   7   8\n")
    8.times do |y|
      print(vert + "\n#{y+1}|")
      8.times do |x|
        case @mainboard.board_arr[y][x]
        when 0 then
          symbol = " "
        when 1 then
          symbol = B
        when -1 then
          symbol = W
        end
        print(" " + symbol + " |")
      end
      print("\n")
    end
    print(vert + "\n\n")
    print(" " * 6 + B + " : " + @black_player.name + " " * 3 + W + " : " + @white_player.name + "\n\n")
  end
end

Game.new