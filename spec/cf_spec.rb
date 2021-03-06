require_relative '../lib/cf_classes.rb'
require 'stringio'

describe ConnectFour do
	subject { game }
	let(:game) { ConnectFour.new }
	
	before { $stdout = StringIO.new }
	before(:each) do 
		allow(game).to receive(:puts)
		allow(game).to receive(:print)
	end
	
	after(:all) { $stdout = STDOUT }
	
	let(:rows) do
		rows = []
		
		(Board::HEIGHT - 1).times do
			rows.push(Array.new(Board::LENGTH) { |i| i = " " })
		end
		
		rows.push([" ", "@", "O", "O", "O", "@", " "])
	end
	
	let(:sample_board) { Board.new(rows) }
	let(:sample_players) { { "Player 1" => "O", "Player 2" => "@" } }
	let(:curr_player) { "Player 1" }
	let(:save_data) { { :current_player => curr_player, :board => sample_board } }
	
	context "when initialized with no arguments" do
		let(:blank_board) { Board.new }
		
		it "initializes with a blank board" do
			expect(game.board).to eq blank_board
			expect(game.board).to be_an_instance_of Board
		end
	end
	
	context "when initialized with an I/O stream" do	
		let(:game) do
			f = StringIO.new("", "r+")
			f.write(YAML.dump(save_data))
			new_game = ConnectFour.new(f)
			f.close
			
			new_game
		end
		
		it "sets the board to the state in the YAML file" do
			expect(game.board).to eq sample_board
		end
	end
	
	it "sets players and their markers" do
		expect(game.players).to eq sample_players
	end
	
	describe ".load" do
		subject { load }
		let(:file_name) do
			File.expand_path("cf_save_example.yml", File.dirname(__FILE__))
		end
		let(:load) { ConnectFour.load(file_name) }
		let(:stream) { File.open(file_name) }
		
		it "accepts one string as an argument" do
			expect { ConnectFour.load(12) }.to raise_error(Errno::EBADF)
			expect { load }.not_to raise_error
		end
		
		it "opens a file with the given name" do
			expect(File).to receive(:open).and_return ConnectFour.new(stream)
			load
		end
		
		it "returns a new game instance" do
			expect(load).to be_an_instance_of ConnectFour
		end
	end
	
	describe ".prompt" do
		subject { prompt }
		let(:one_arg) { ConnectFour.prompt("This will fail") }
		let(:message) { "Test message" }
		let(:valid_args) { ["yes", "maybe", "no"] }
		let(:block_result) { 2 }
		let(:block) { lambda { |answer| return block_result } }
		let(:no_block) do
			allow(STDIN).to receive(:gets).and_return(valid_args.sample)
			ConnectFour.prompt(message, valid_args)
		end
		
		let(:prompt) do 
			expect(ConnectFour).to receive(:gets).and_return valid_args.sample
			ConnectFour.prompt(message, valid_args, &block)
		end
		
		it "accepts two arguments" do
			expect { one_arg }.to raise_error(ArgumentError)
		end
		
		it "expects a string, array, and a block" do
			expect(message).to be_an_instance_of String
			expect(valid_args).to be_an_instance_of Array
			expect{ prompt }.not_to raise_error
		end
		
		it "prints the given string" do
			expect(ConnectFour).to receive(:puts).with(message)
			prompt
		end
		
		it "executes the block if a valid response is given" do
			expect(prompt).to eq block_result
		end
	end
	
	describe "#save" do		
		let(:save) do
			f = StringIO.new("", "r+")
			f.write(YAML.dump(save_data))
			
			game.save(f)
			f
		end
		
		let(:load) do
			f = save	
			board_state = ConnectFour.new(f).board
			f.close
			
			board_state
		end
		
		it "takes one argument" do
			expect { save }.not_to raise_error
		end 
		
		it "saves the correct data" do
			expect(load).to eq sample_board
		end
	end

	describe "#save_and_quit" do
		let(:game) { ConnectFour.new }

		before(:each) do
			allow(game).to receive(:gets).and_return("test_file.yml")
			allow(STDERR).to receive(:puts).with("Saving to file \"test_file.yml\" and quitting... goodbye.")
			allow(game).to receive(:abort)

			expect(game).to receive(:save_and_quit).and_call_original
		end

		after(:all) { File.unlink("test_file.yml") }

		it "saves the game" do
			expect(game).to receive(:save).with(an_instance_of File)
			game.save_and_quit
		end

		it "ends the program" do
			expect(game).to receive(:abort)
			game.save_and_quit
		end
	end

	describe "#play" do
		let(:game) { ConnectFour.new }
		let(:win_message) { "\nPlayer 1 is the winner!" }
		let(:draw_message) { "\nThe game is a draw!" }
		let(:full_board) do
			rows = []

			0.upto (Board::HEIGHT - 1) do |i|
				curr_row = []

				0.upto(Board::LENGTH - 1) do |j|
					multiple_of_four = ((i + 1) % 4 == 0)

					case 
						when i == Board::HEIGHT - 1 && j == Board::LENGTH - 1
							curr_row << " "
						when multiple_of_four && (j.even? || j.zero?)
							curr_row << "@"
						when !multiple_of_four && j.odd?
							curr_row << "@"
						else
							curr_row << "O"
					end
				end

				rows.push(curr_row)
			end

			Board.new(rows)
		end

		let(:draw_game) do
			mock_file = StringIO.new(YAML::dump({ :current_player => "Player 1", :board => full_board }))
			ConnectFour.new(mock_file)
		end

		it "prints the winner if a player wins" do
			allow(ConnectFour).to receive(:gets).and_return("1", "2", "1", "2", "1", "2", "1", "2", "1")
			expect(game).to receive(:puts).with(win_message)
			game.play
		end

		it "notifies the player if the game is a draw" do
			allow(ConnectFour).to receive(:gets).and_return(Board::LENGTH.to_s)
			expect(draw_game).to receive(:puts).with(draw_message)
			draw_game.play
		end
	end
end

describe Board do
	subject { board }
	let(:empty_rows) { Array.new(Board::HEIGHT) { |i| i = Array.new(Board::LENGTH) { |j| i = " " } } }
	let(:empty_board) { Board.new }
	let(:sample_rows) do
		rows = []
		
		(Board::HEIGHT - 1).times do
			rows.push(Array.new(Board::LENGTH) { |i| i = " " })
		end
		
		rows.push([" ", "@", "O", "O", "O", "@", " "])
	end
	let(:saved_board) { Board.new(sample_rows) }
	
	it "contains an array of arrays" do
		expect(empty_board.rows).to be_an_instance_of Array
		expect(empty_board.rows).to all(be_an_instance_of Array)
	end
	
	it "is equal to a board with identical rows" do
		expect(saved_board).to eq Board.new(sample_rows)
	end

	describe "@rows" do
		context "when the board is initialized with no arguments" do
			it "has all blank rows" do
				expect(empty_board.rows).to eq empty_rows
			end
		end
		
		context "when the board is initialized with a valid array" do
			it "sets the rows equal to the array" do
				expect(saved_board.rows).to eq sample_rows
			end
		end
		
		it "has a number of rows equal to the board's height" do
			expect(empty_board.rows.length).to eq Board::HEIGHT
		end
		
		it "has a row length equal to the board's length" do
			expect(empty_board.rows.all? { |r| r.length == Board::LENGTH }).to be true
		end
	end

	describe "#four_in_row?" do
		let(:row_idx) { 5 }
		let(:col_idx) { 3 }
		let(:token) { "O" }
		let(:board) { saved_board }
		subject { board.four_in_row?(row_idx, col_idx, token) }

		it "takes a row index, column index, and string as arguments" do
			expect { saved_board.four_in_row?(row_idx, col_idx, token) }.not_to raise_error
			expect { saved_board.four_in_row?("this", "will", "fail") }.to raise_error(TypeError)
			expect { saved_board.four_in_row?(row_idx, col_idx) }.to raise_error(ArgumentError)
		end

		context "when there are four in a row horizontally" do
			let(:four_in_row) do
				rows = []
			
				(Board::HEIGHT - 1).times do
					rows.push(Array.new(Board::LENGTH) { |i| i = " " })
				end
				
				rows.push([" ", "@", "O", "O", "O", "O", " "])
			end
			let(:board) { Board.new(four_in_row) }

			it { is_expected.to be true }
		end

		context "when there are four in a row vertically" do
			let(:row_idx) { 3 }
			let(:four_in_row) do
				rows = []

				4.times do
					rows.push([" ", " ", " ", "O", " ", " ", " "])
				end

				(Board::HEIGHT - 4).times do
					rows.push([" ", " ", " ", " ", " ", " ", " "])
				end

				rows
			end
			let(:board) { Board.new(four_in_row) }

			it { is_expected.to be true }
		end

		context "when there are four in a row on a northwest diagonal" do
			let(:row_idx) { 0 }
			let(:four_in_row) do
				rows = []
				placement = 3

				Board::HEIGHT.times do |i|
					curr_row = []

					Board::LENGTH.times do |j|
						if placement > -1 && j == placement
							curr_row << token
							placement -= 1
						else
							curr_row << " "
						end
					end

					rows.push(curr_row)
				end

				rows
			end

			let(:board) { Board.new(four_in_row) }

			it { is_expected.to be true }
		end

		context "when there are four in a row on a northeast diagonal" do
			let(:row_idx) { 0 }
			let(:four_in_row) do
				rows = []
				placement = 0

				Board::HEIGHT.times do |i|
					curr_row = []

					Board::LENGTH.times do |j|
						if placement < 4 && j == placement
							curr_row << token
							placement += 1
						else
							curr_row << " "
						end
					end

					rows.push(curr_row)
				end

				rows
			end

			let(:board) { Board.new(four_in_row) }

			it { is_expected.to be true }
		end
	end

	describe "#full?" do
		let(:full_board) do
			rows = []

			0.upto (Board::HEIGHT - 1) do |i|
				curr_row = []

				0.upto(Board::LENGTH - 1) do |j|
					multiple_of_four = ((i + 1) % 4 == 0)

					case 
						when multiple_of_four && (j.even? || j.zero?)
							curr_row << "@"
						when !multiple_of_four && j.odd?
							curr_row << "@"
						else
							curr_row << "O"
					end
				end

				rows.push(curr_row)
			end

			Board.new(rows).full?
		end

		let(:partial) do
			rows = []
			first_row = []

			0.upto (Board::LENGTH - 1) do |i|
				if i.even? || i.zero?
					first_row << "0"
				else
					first_row << "@"
				end
			end

			rows.push(first_row)

			(Board::HEIGHT - 1).times do
				curr_row = []
				Board::LENGTH.times do
					curr_row << " "
				end

				rows.push(curr_row)
			end

			Board.new(rows).full?
		end

		let(:empty_board) { Board.new.full? }

		it "returns true for an entirely full board" do
			expect(full_board).to be true
			expect(partial).to be false
			expect(empty_board).to be false
		end
	end

	describe "#place_token" do
		let(:new_board) { Board.new }
		let(:token) { "O" }
		let(:full_column) do
			rows = []

			Board::HEIGHT.times do |i|
				curr_row = []

				if i == 0 || i.even?
					curr_row << "O"
				else
					curr_row << "@"
				end

				(Board::LENGTH - 1).times { curr_row << " " }
				
				rows.push(curr_row)
			end

			Board.new(rows)
		end

		let(:example_board) do
			rows = [["O", "@"]]

			(Board::LENGTH - 2).times { rows[0] << " " }

			rows.push([" ", "O"])

			(Board::LENGTH - 2).times { rows[1] << " " }

			(Board::HEIGHT - 2).times do
				curr_row = []

				Board::LENGTH.times do 
					curr_row << " "
				end

				rows.push(curr_row)
			end

			Board.new(rows)
		end

		let(:board_ex_1) do
		 example_board.place_token(token, 0) 
		 example_board.rows[1][0]
		end

		let(:board_ex_2) do
		 example_board.place_token(token, 1)
		 example_board.rows[2][1]
		end

		let(:board_ex_3) do
			example_board.place_token(token, 2)
			example_board.rows[0][2]
		end

		let(:full_col_index) { 0 }

		it "takes a token and a column index as arguments" do
			expect { new_board.place_token(token, 1) }.not_to raise_error
			expect { new_board.place_token(token, "col") }.to raise_error(ArgumentError)
		end

		it "raises InvalidInputError if column is full" do
			expect { full_column.place_token(token, full_col_index) }.to raise_error(InvalidInputError)
		end

		it "places the given token in the first empty row" do
			expect(board_ex_1).to eq token
			expect(board_ex_2).to eq token
			expect(board_ex_3).to eq token
		end
	end
end