class Attacks
	attr_accessor :attacks
	def initialize(id)
		res = $conn.query("SELECT attack_num, name, attack_bonus, damage, min_crit, crit_mult, special FROM c_attacks WHERE cid = #{id}")
		ind = {}
		@attacks = []
		cur = 0
		while row = res.fetch_row
			num = row[0].to_i
			if ind[num]
				num = ind[num]
			else
				ind[num] = cur
				num = cur
				cur += 1
			end
			@attacks[num] = [] unless @attacks[num]
			@attacks[num].push(Attack.new(row[1], row[2], row[3], convert_int(row[4]), convert_int(row[5]), row[6]))
		end
	end

	def to_s
		return @attacks.map{|group| group.map{|attack| attack.to_s}.join(", ")}.join("\n")
	end

	def attack_lines
		return @attacks.map{|group| group.map{|attack| attack.to_s}.join(", ")}
	end

	def empty?
		attacks.empty?
	end
end

class Attack
	attr_accessor :name, :attack_bonus, :damage, :min_crit, :crit_mult, :special
	def initialize(name, attack_bonus, damage, min_crit, crit_mult, special)
		@name = name
		@attack_bonus = attack_bonus
		@damage = damage
		@min_crit = min_crit
		@crit_mult = crit_mult
		@special = special
	end

	def to_s
		ret = "#{@name} #{@attack_bonus} (#{@damage}"
		ret += "/#{@min_crit}-20" if @min_crit < 20
		ret += "/x#{crit_mult}" if @crit_mult > 2
		ret += " plus #{@special}" if @special
		ret += ")"
	end
end
