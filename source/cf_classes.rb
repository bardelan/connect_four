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
		if stream
			stream.seek(0) # guarantee that we are at the beginning of the file
			@board = YAML.load(stream.read)
		else
			@board = Board.new
		end
	end
	
	def save(stream)
		stream.write(YAML.dump(@board))	
	end
end

class Board
	attr_reader :rows

	def initialize(rows = nil)
		rows ||= Array.new(6) { |i| i = Array.new(7) { |j| i = " " } }
		@rows = rows
	end
	
	def ==(other_board)
		other_board.is_a?(Board) && other_board.rows == @rows
	end
	
	
end