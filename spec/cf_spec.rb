require_relative '../source/cf_classes.rb'
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
	
	let(:sample_board) do
		rows = []
		
		5.times do
			rows.push(Array.new(7) { |i| i = " " })
		end
		
		rows.push([" ", "@", "O", "O", "O", "@", " "])
		
		Board.new(rows)
	end
	
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
			f.write(YAML.dump(sample_board))
			new_game = ConnectFour.new(f)
			f.close
			
			new_game
		end
		
		it "sets the board to the state in the YAML file" do
			expect(game.board).to eq sample_board
		end
	end
	
	describe ".main" do
		subject { main }
		let(:main) { ConnectFour.main	}
		let(:save_file) { File.open("cf_save_example.yml") }
		
		it "accepts \"new\" or \"load\" as input" do
			expect(ConnectFour).to receive(:gets).and_return "new"
			expect { main }.not_to raise_error
		end
		
		context "when the user chooses \"load\"" do			
			it "loads the given file" do
				expect(ConnectFour).to receive(:gets).and_return("load", "cf_save_example.yml")
				expect(ConnectFour).to receive(:load).and_return ConnectFour.new(save_file)
				expect { main }.not_to raise_error
			end
		end
	end
	
	describe ".load" do
		subject { load }
		let(:file_name) { "cf_save_example.yml" }
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
			f.write(YAML.dump(sample_board))
			
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
end