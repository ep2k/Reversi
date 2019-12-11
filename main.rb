# 定数
X = 0; Y = 1
STONE = 64 # 全マス数
B = "\e[#{31}m●\e[0m"; W = "\e[#{32}m●\e[0m" # 石の描画
BN = "\e[#{31}m■\e[0m"; WN = "\e[#{32}m■\e[0m" # 石の描画
COORD = 0..7 # 正しい座標の範囲
ARROUND = [[-1,-1],[0,-1],[1,-1],[-1,0],[1,0],[-1,1],[0,1],[1,1]] 

class Board
  
  attr_accessor :turn
  attr_reader :stone
  attr_reader :black
  attr_reader :white
  attr_accessor :board_arr
  attr_accessor :arround
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
      x = hand[X]+ARROUND[i][X]; y = hand[Y]+ARROUND[i][Y]
      count = 0
      while true
        if !COORD.include?(x) || !COORD.include?(y)
          count = 0
          break
        end
        case @board_arr[y][x]
        when @turn then
          break
        when 0 then
          count = 0
          break
        end
        count += 1
        x += ARROUND[i][X]; y += ARROUND[i][Y]
      end
      count.times do |j|
        board_arr[hand[Y]+(j+1)*ARROUND[i][Y]][hand[X]+(j+1)*ARROUND[i][X]] = @turn
      end
      @black += @turn * count
      @white -= @turn * count
    end
    self.update_arround(hand)
    @turn == 1 ? @black += 1 : @white += 1
    @stone += 1
    @turn *= -1
  end
  def check(hand) # 指し手が合法手であるか判定しtrue/falseを返す
    # moveメソッドのうち、必要のない処理を省略した
    unless @board_arr[hand[Y]][hand[X]] == 0
      return false
    end
    8.times do |i|
      x = hand[X]+ARROUND[i][X]; y = hand[Y]+ARROUND[i][Y]
      count = 0
      while true
        if (!COORD.include?(x) || !COORD.include?(y))
          count = 0
          break
        end
        case @board_arr[y][x]
        when @turn then
          break
        when 0 then
          count = 0
          break
        end
        count += 1
        x += ARROUND[i][X]; y += ARROUND[i][Y]
      end
      if count > 0 then return true end
    end
    return false
  end
  def generate # 合法手の配列を返す
    legal = Array.new
    @arround.each do |hand|
      if self.check(hand) then legal.push(hand.dup) end
    end
    return legal
  end
  def update_arround(move) # @arroundの更新
    @arround.delete(move)
    8.times do |i|
      tmp = [move[X] + ARROUND[i][X], move[Y] + ARROUND[i][Y]]
      if (!COORD.include?(tmp[X]) || !COORD.include?(tmp[Y])) then next end
      if @board_arr[tmp[Y]][tmp[X]] == 0 then @arround.push(tmp).uniq! end
    end
  end
  def win_player
    if @black > @white
      return 1
    elsif @black < @white
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
      unless hand_input[1] == " "
        print("\nPlease input in correct format. ex. 4 5\n> ")
        next
      end
      hand = [hand_input[0].to_i - 1, hand_input[2].to_i - 1]
      if (!COORD.include?(hand[0]) || !COORD.include?(hand[1])) # 盤外
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
    return tryout(board)
  end
  def tryout(board) # 指定回数トライアウトをし、最大勝率の手を返す
    can_move = board.generate # 合法手列挙
    move_number = can_move.length # 合法手の数
    try = @try_times / move_number # 1手あたりのトライアウト数
    max_move = 0 # 勝利数が最大の手
    max_win = 0 # 最大の勝利数
    can_move.each_index do |i|
      board_i = Marshal.load(Marshal.dump(board))
      board_i.move(can_move[i])
      win = 0
      try.times do
        tmp_board = Marshal.load(Marshal.dump(board_i))
        # ランダムに手を選び終局まで進める
        endflg = false
        until tmp_board.stone == STONE
          tmp_can_move = tmp_board.generate
          if tmp_can_move.empty? # パスの処理
            if(endflg)
              break
            else
              endflg = true
              tmp_board.turn *= -1
              next
            end
          end
          tmp_board.move(tmp_can_move.sample) # 合法手の一覧からランダムに取り出して実行する
          endflg = false
        end
        if tmp_board.win_player == @turn then win += 1 end
      end
      if win > max_win
        max_move = i; max_win = win
      end
    end
    return can_move[max_move]
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
    print("Please choose(1~3).\n1:Human vs Human\n2:Human vs CPU\n3:CPU vs CPU\n> ")
    while true
      mode = gets.chomp.to_i
      if (1..3).include?(mode) then break end
      print("\nPlease input correct number! (1~3)\n> ")
    end
    print("\n")
    case mode
    when 1 then
      @black_player = Human.new(1)
      @white_player = Human.new(2)
    when 2 then
      print("You are first? Yes(1)/No(2)/Random(3)\n> ")
      while true
        tmp = gets.chomp.to_i
        if (1..3).include?(tmp) then break end
        print("\nPlease input correct number! (1~3)\n> ")
      end
      print("\nCPU's try times(natural number)?\n> ")
      while true
        try_times = gets.chomp.to_i
        if try_times > 0 then break end
        print("\nPlease input natural number.\n> ")
      end
      if tmp == 3 then tmp = rand(2) end
      if tmp == 1
        @black_player = Human.new(-1)
        @white_player = CPU.new(-1,try_times)
      else
        @black_player = CPU.new(1,try_times)
        @white_player = Human.new(-2)
      end
    when 3 then
      print("1st CPU's try times(natural number)?\n> ")
      while true
        first_try = gets.chomp.to_i
        if first_try > 0 then break end
        print("\nPlease input natural number.\n> ")
      end
      print("\n2nd CPU's try times(natural number)?\n> ")
      while true
        second_try = gets.chomp.to_i
        if second_try > 0 then break end
        print("\nPlease input natural number.\n> ")
      end
      @black_player = CPU.new(1,first_try)
      @white_player = CPU.new(-1,second_try)
    end
  end
  def play
    endflg = false
    until(@mainboard.stone == STONE)
      self.display_board
      if @mainboard.generate.length == 0
        if endflg
          break
        else
          endflg = true
          @mainboard.turn *= -1
          next
        end
      end
      if @mainboard.turn == 1
        nextmove = @black_player.move(Marshal.load(Marshal.dump(@mainboard)))
      else
        nextmove = @white_player.move(Marshal.load(Marshal.dump(@mainboard)))
      end
      self.display_board(nextmove)
      sleep(1)
      @mainboard.move(nextmove)
    end
    self.display_board
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
  def display_board(new_pos=nil)
    puts "\e[H\e[2J"
    can_move = @mainboard.generate
    vert = "  --- --- --- --- --- --- --- ---"
    print("\n   1   2   3   4   5   6   7   8\n")
    8.times do |y|
      print(vert + "\n#{y+1}|")
      8.times do |x|
        if [x,y] == new_pos
          case @mainboard.turn
          when 1 then
            symbol = BN
          when -1 then 
            symbol = WN
          end
        else
          case @mainboard.board_arr[y][x]
          when 0 then
            symbol = can_move.include?([x,y]) ? "-" : " "
          when 1 then
            symbol = B
          when -1 then
            symbol = W
          end
        end
        print(" " + symbol + " |")
      end
      print("\n")
    end
    print(vert + "\n\n")
    print(" " * 6 + B + " : #{@black_player.name}(#{@mainboard.black})" + " " * 3 + W + " : #{@white_player.name}(#{@mainboard.white})\n\n")
  end
end

Game.new