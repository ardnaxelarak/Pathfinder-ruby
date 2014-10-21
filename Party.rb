require_relative 'Character'
require_relative 'Setup'
require_relative 'Functions'

class Party
	include Enumerable

	attr_reader :party
	attr_accessor :verbose
	def initialize(id = nil, verbose = false)
		@party = []
		@verbose = verbose
	end

	def add(char)
		c = nil
		if char.is_a?(Fixnum)
			c = Character.new(char, nil, verbose)
		elsif char.is_a?(String)
			id = lookup_character(char, verbose)
			c = Character.new(id, nil, verbose)
		elsif char.is_a?(Character)
			c = char
		else
			c = Character.new(create_character, nil, verbose) if verbose
		end
		return false unless c
		@party.push(c)
		return c
	end

	def [](index)
		return party[index]
	end

	def each(&block)
		@party.each(&block)
	end

	def roll_init
		puts "Enter initiatives:"
		for c in @party
			print "#{c.cname}: "
			c.cur_init = gets.chomp.to_i
		end
	end
end
