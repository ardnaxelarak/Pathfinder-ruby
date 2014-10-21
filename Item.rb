def get_character_items(id)
	res = $conn.query("SELECT items.id, name, text, num FROM c_items LEFT JOIN items ON c_items.item = items.id WHERE cid = #{id}")
	items = []
	while row = res.fetch_row
		(id, name, text, num) = row
		id = id.to_i
		num = roll(num)
		items.push(Item.new(id, name, text, num))
	end
	return items
end

class Item
	attr_reader :id, :name, :text, :num
	def initialize(id, name, text, num = 1)
		@id = id
		@name = name
		@text = text
		@num = num
	end

	def to_s
		return name if num == 1
		"#{name} (#{num})"
	end

	def use
		@num -= 1
		return num > 0
	end
end
