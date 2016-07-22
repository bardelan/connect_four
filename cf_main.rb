require_relative "./lib/cf_classes.rb"
	
loop do
	puts "New game or load save file?" 
	
	ConnectFour.prompt("Enter 'new' or 'load': ", ["new", "load"]) do |response|
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
			
			game = ConnectFour.load(file_name)
		end

	game.play
	end

	ConnectFour.prompt("\nPlay again?", ["y", "n", "yes", "no"]) do |response|
		break if response[0] == "n"
	end
end
