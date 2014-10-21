require_relative 'Setup'
require_relative 'CreateFunctions'
require_relative 'Character'
require 'launchy'

class Encounter
	attr_reader :characters, :order, :cur_turn
	attr_accessor :verbose
	def initialize(id = nil)
		@characters = {}
		@order = []
		@verbose = true
		if id
			res = $conn.query("SELECT creature, num FROM e_creatures WHERE eid = #{id}")
			while row = res.fetch_row
				num = roll(row[1])
				add(nil, row[0].to_i, num)
				puts order.size
			end
		end
	end

	def add(name, char, num = 1)
		return unless num >= 1
		id = nil
		if (char.is_a?(Fixnum))
			id = char
		elsif (char.is_a?(String))
			id = lookup_character(char, verbose)
		else
			id = create_character if verbose
		end
		return false unless id
		list = []
		for i in 1..num
			c = Character.new(id, nil, verbose)
			name = c.name unless name
			if (num > 1)
				curname = "#{name} #{i}"
			else
				curname = name
			end
			c.cname = curname
			@characters[curname] = c
			list.push(c)
			@order.push(curname)
			c.roll_init
		end
		sort_init
		return list if num > 1
		return list[0]
	end

	def add_party(party)
		for char in party
			name = char.name
			@characters[name] = char
			@order.push(name)
		end
		party.roll_init
		sort_init
	end

	def hide(char)
		if (char.is_a?(Character))
			ind = @characters.key(char)
			@order.delete(ind)
		elsif (char.is_a?(Fixnum))
			@order.slice!(char)
		elsif (char.is_a?(String))
			@order.delete(char)
		end
	end

	def show(char)
		ind = nil
		if (char.is_a?(Character))
			ind = @characters.key(char)
		elsif (char.is_a?(String))
			ind = char
		end
		if (ind && !@order.include?(ind))
			@order.push(ind)
			sort_init
		end
	end

	def [](index = nil)
		index = cur_turn unless index
		if (index.is_a?(Fixnum))
			return characters[order[index]]
		else
			return characters[index]
		end
	end

	def sort_init
		cur_char = order[cur_turn] if cur_turn
		@order.sort_by! do |key|
			char = @characters[key]
			-1 * (char.cur_init * 100000000 + char.dex * 1000000 + char.initiative * 10000 + char.wis * 100 + rand(100))
		end
		@cur_turn = @order.index(cur_char) if cur_turn
	end

	def p_init
		for name in @order
			puts char_status_line(name)
		end
	end

	def char_status_line(name)
		char = @characters[name]
		if (char.conditions.length > 0)
			return "#{name} - #{char.name} [#{char.cur_init}] (#{char.conditions.join(", ")})"
		else
			return "#{name} - #{char.name} [#{char.cur_init}]"
		end
	end

	def print_order
		for i in (cur_turn...order.size)
			puts char_status_line(order[i])
		end
		for i in (0...cur_turn)
			puts char_status_line(order[i])
		end
	end

	def print_current
		name = order[cur_turn]
		puts name
		char = characters[name]
		char.print_status
	end

	def next_turn
		@cur_turn = -1 unless cur_turn
		@cur_turn = (cur_turn + 1) % order.size
	end

	def proceed
		next_turn
		self[].apply_healing
		print_current
		nil
	end

	def open_pages
		urls = @characters.values.map{|char| char.url}.uniq.select{|url| url}
		for url in urls
			Launchy.open(url)
		end
	end

	def start
		@cur_turn = 0
	end
end
