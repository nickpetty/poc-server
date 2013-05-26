#!/usr/bin/ruby
require 'socket'
require 'yaml'
require 'fileutils'
require 'colorize'

def clear
    system("clear")
    system("cls")
end

clear

puts "Starting up server... #{Time.now}"

@server = TCPServer.new(2008)


class Users
    attr_accessor :users

    def users
        @users
    end

  def defaults
		user = {}
		user["admin"] = "password"
		File.open("users.yaml", "w") do |f|
			f.write(user.to_yaml)
		end
	end
	
	def load
		@users = YAML.load_file("users.yaml")
		if @users == false
			FileUtils.touch ('users.yaml')
			@users = YAML.load_file("users.yaml")
		end
		
	end

	def add(user, pass)
		load
		@users[user] = pass
		
		File.open("users.yaml", "w") do |f|
			f.write(@users.to_yaml)
		end
        return "User: #{user} added.\r\n"
	end
	
	def rm(user)
		load
		@users.delete(user)
		
		File.open("users.yaml", "w") do |f|
			f.write(@users.to_yaml)
		end
		return "User #{user} removed.\r\n"
	end
	
    def list
        @users.keys
    end
end


users_class = Users.new

if !File.exists?("users.yaml")
    users_class.defaults
end

def main
    loop do
        Thread.start(@server.accept) do |client|
            users_class = Users.new
            @client = client
            @host = Socket.gethostname
            

            def select(cmd)
                users_class = Users.new
                case cmd
                    when '1'
                        @client.print "This is 1.\r\n"
                    when '2'
                        @client.print "This is 2.\r\n"
                end
            end

            def parse(ary = [])
                users_class = Users.new

                if ary[0].include?("source")
                    line_num = 0
                    source = File.open(ary[1])
                    source.each_line do |line|
                    @client.print "#{line_num +=1} " + line.chomp.green + "\r\n"
                    end
                    puts "#{@user} viewed source of #{ary[1]}"
                end

                if ary[0].include?("users")

                    if ary[1].include?("add")
                        @client.print users_class.add(ary[2], ary[3])
                        puts "#{@user} added #{users_class.add(ary[2], ary[3])}"
                    end

                    if ary[1].include?("list")
                        users_class.load
                        @client.print "Listing Users:\r\n"
                        u = users_class.list
                        u.each do |k|
                            @client.print k + "\r\n"
                        end
                    end
                    
                    if ary[1].include?("rm")
                    	@client.print users_class.rm(ary[2])
					end
					
                end
            end

            #users_class.users = users_class.load
            client.print "Username: "
            @user = client.gets.chomp
            client.print "Password: "
            pass = client.gets.chomp
            users_class.load

            if users_class.users.has_key?(@user) && users_class.users.key(pass) == @user
            	puts "User #{@user} logged in from #{client.peeraddr[2]} at #{Time.now}"
                input = ''

                while input != 'logout'

                   	client.print "#{@user}@#{@host}-: "
                   	input = client.gets.chomp
                    input_ary = input.split(" ")
                    parse(input_ary)
    				select(input)
                    puts "Input from #{@user}: #{client.peeraddr[2]}: #{input}"

                end
                
                if input == 'logout'
                    puts "User #{@user} logged out at #{Time.now}"
                    client.close
                end

             else
                client.print "Denied\r\n"
                client.print "Disconnecting \r\n"
                client.close
            end
        end
    end
end
main
