require 'yaml'

class InvalidInputError < StandardError; end
class InvalidFileName < InvalidInputError; end

class ConnectFour
	attr_reader :board, :players
	
	def self.main
		puts "New game or load save file?" 
		
		prompt("Enter 'new' or 'load': ", ["new", "load"]) do |response|
			if response == "new"
				game = ConnectFour.new
			else
				begin
					puts "Please enter the file name: "
					file_name = gets.chomp
					
					raise InvalidFileName unless File.file?(file_name)
				rescue InvalidFileName => e
					puts "Sorry, that file name is not valid."
					retry
				end		
				
				game = load(file_name)
			end
		end
	end
	
	def self.load(file_name)
		File.open(file_name) do |f|
			ConnectFour.new(f)
		end
	end
	
	def self.prompt(message, valid_responses)		
		begin 
			puts message
			action = gets.strip.downcase
			
			valid_responses.each { |response| response.strip.downcase }
			raise InvalidInputError unless valid_responses.include? action
		rescue InvalidInputError => e
			puts "Invalid response. Please choose from #{ valid_responses.join(", ") }."
			retry
		end
		
		yield action
	end
	
	def initialize(stream = nil)
		if stream.nil?
			@board = Board.new
		else
			stream.seek(0) # guarantee that we are at the beginning of the file
			@board = YAML.load(stream.read)
		end
		
		@players = { "Player 1" => "O", "Player 2" => "@" }
	end
	
	def save(stream)
		stream.write(YAML.dump(@board))	
	end

	def play

	end
end

class Board
	attr_reader :rows
	
	HEIGHT = 6
	LENGTH = 7

	def initialize(rows = nil)
		rows ||= Array.new(HEIGHT) { |i| i = Array.new(LENGTH) { |j| j = " " } }
		
		raise InvalidInputError unless rows.length == HEIGHT && rows.all? { |r| r.length == LENGTH }
		
		@rows = rows
	end
	
	def ==(other_board)
		other_board.is_a?(Board) && other_board.rows == @rows
	end
	
	def empty_cell?(row, col)
		@rows[row-1][col] == " "
	end
	
	def four_in_row?(row, col, token)
		vertical_win?(row, col, token) || 
		horizontal_win?(row, col, token) || 
		diagonal_win?(row, col, token)
	end
	
	def render
		(HEIGHT-1).downto(0) do |row|
			LENGTH.times { print " - " }
			print "\n"
			
			LENGTH.times do |col|
				print "|#{@rows[row][col]}|"
			end
			
			print "\n"
			LENGTH.times { print " - " }
			print "\n"
		end
	end
	
	def check_for_four(token, &forward, &back)
		continue = { :fwd => true, :back => true }
		count = { :fwd => 0, :back => 0 }
		cells = { :fwd => forward, :back => back }
		
		1.upto 3 do |i|
			[:fwd, :back].each do |d|
				if continue[d]
					if cells[d].call(i) == token
						count[d] += 1
					else
						continue[d] = false
					end
				end
			end
		end
		
		count[:fwd] + count[:back] == 3
	end
	
	def diagonal_win?(row, col, token)
		diag_ne_win?(row, col, token) || diag_nw_win?(row, col, token)
	end
	
	def diag_ne_win?(row, col, token)
		fwd = Proc.new { |i| @rows[row + i][col + i] }
		back = Proc.new { |i| @rows[row + i][col - i] }
		
		check_for_four(token, fwd, back)
	end
	
	def diag_nw_win?(row, col, token)
		fwd = Proc.new { |i| @rows[row - i][col + i] }
		back = Proc.new { |i| @rows[row - i][col - i] }
		
		check_for_four(token, fwd, back)
	end
	
	def horizontal_win?(row, col, token)
		fwd = Proc.new { |i| @rows[row][col + i] }
		back = Proc.new { |i| @rows[row][col - i] }
		
		check_for_four(token, fwd, back)
	end
	
	def vertical_win?(row, col, token)
		fwd = Proc.new { |i| @rows[row + i][col] }
		back = Proc.new { |i| @rows[row - i][col] }
		
		check_for_four(token, fwd, back)
	end
end