class Conditions
	def initialize
		res = $conn.query("SELECT id, name, text FROM conditions")
		@cond = {}
		while row = res.fetch_row
			id = row[0].to_i
			@cond[id] = Condition.new(row[0].to_i, row[1], row[2])
		end
	end

	def [](index)
		return @cond[index]
	end

	def from_name(name)
		for cond in @cond.values
			return cond if cond.name.downcase == name.downcase
		end
		return nil
	end
end

class Condition
	attr_reader :id, :name, :text
	def initialize(id, name, text)
		@id = id
		@name = name
		@text = text
	end

	def to_s
		name
	end
end
