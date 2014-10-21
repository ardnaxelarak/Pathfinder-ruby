# encoding: utf-8

require_relative 'Functions'
require_relative 'Setup'

def not_found(name)
	print("'#{name}' not found. Create? ([yes]/no/typo) ")
	ans = gets.chomp
	ans_d = ans.downcase
	return true if ans == "" || ans_d == "yes"
	return false if ans_d == "no"
	return ans[5..-1] if (ans_d.start_with? "typo ")
	return not_found(name)
end

def confirm(text, default = true)
	if default
		print("#{text} ([yes]/no) ")
	else
		print("#{text} (yes/[no]) ")
	end
	ans = gets.chomp
	ans_d = ans.downcase
	return default if ans == ""
	return true if ans_d == "yes"
	return false if ans_d == "no"
	return confirm(text)
end

def lookup_feat(name)
	res = $conn.query("SELECT id FROM feats WHERE name = #{escape(name)}")
	if row = res.fetch_row
		return row[0].to_i
	end
	ans = not_found(name)
	return nil unless ans
	return lookup_feat(ans) unless ans == true
	puts "Feat Description:"
	text = gets
	text.chomp! if text
	text = nil if text == ""
	$conn.query("INSERT INTO feats (name, text) VALUES (#{escape(name)}, #{escape(text)})")
	return $conn.insert_id
end

def lookup_item(name)
	res = $conn.query("SELECT id FROM items WHERE name = #{escape(name)}")
	if row = res.fetch_row
		return row[0].to_i
	end
	ans = not_found(name)
	return nil unless ans
	return lookup_feat(ans) unless ans == true
	puts "Item Description:"
	text = gets
	text.chomp! if text
	text = nil if text == ""
	$conn.query("INSERT INTO items (name, text) VALUES (#{escape(name)}, #{escape(text)})")
	return $conn.insert_id
end

def lookup_language(name)
	res = $conn.query("SELECT id FROM languages WHERE name = #{escape(name)}")
	if row = res.fetch_row
		return row[0].to_i
	end
	ans = not_found(name)
	return nil unless ans
	return lookup_language(ans) unless ans == true
	$conn.query("INSERT INTO languages (name) VALUES (#{escape(name)})")
	return $conn.insert_id
end

def lookup_skill(name)
	res = $conn.query("SELECT id FROM skills WHERE name = #{escape(name)}")
	if row = res.fetch_row
		return row[0].to_i
	end
	ans = not_found(name)
	return nil unless ans
	return lookup_skill(ans) unless ans == true
	puts "Sorry, not gonna bother coding that option."
	return nil
end

def lookup_character(char, verbose = true)
	id = nil
	res = $conn.query("SELECT id FROM characters WHERE name = #{escape(char)}")
	if row = res.fetch_row
		id = row[0].to_i
	end
	if !id && verbose
		ans = not_found(char)
		return nil unless ans
		return lookup_character(char, verbose) unless ans == true
		id = create_character
	end
	return id
end

def create_character
	values = []
	print "Name: "
	values.push(read_string)
	print "CR: "
	values.push(read_float)
	print "Abilities: "
	values += read_int(6)
	print "BAB: "
	values.push(read_int)
	print "Initiative modifier: "
	values.push(read_int)
	print "Land speed: "
	values.push(read_int)
	print "Fly speed: "
	fly_speed = read_int
	values.push(fly_speed)
	if (fly_speed)
		print "Fly maneuverability: "
		values.push(read_string)
	else
		values.push(nil)
	end
	print "Swim speed: "
	values.push(read_int)
	print "Climb speed: "
	values.push(read_int)
	print "Burrow speed: "
	values.push(read_int)
	print "Space: "
	values.push(read_int(1, 5))
	print "Reach: "
	values.push(read_int(1, 5))
	print "AC: "
	values += read_int(3)
	print "HP: "
	values.push(read_string)
	values.push(confirm("Ferocity?", false))
	print "Fast Healing: "
	values.push(read_int)
	values += read_int_type("Regeneration: ")
	print "Saves: "
	values += read_int(3)
	values += read_int_type("DR: ")
	print "SR: "
	values.push(read_int)
	print "URL: "
	values.push(read_string)

	$conn.query("INSERT INTO characters (name, cr, strength, dexterity, constitution, intelligence, wisdom, charisma, base_attack_bonus, initiative, speed, fly_speed, fly_maneuver, swim_speed, climb_speed, burrow_speed, space, reach, ac, touch_ac, flat_footed_ac, hp, ferocity, fast_healing, regeneration, regeneration_bypass, fort, ref, will, dr, dr_bypass, sr, url) VALUES (#{values.map{|value| escape(value)}.join(", ")})")
	id = $conn.insert_id

	puts "Languages:"
	add_languages(id)

	puts "Feats:"
	add_feats(id)

	puts "Skills:"
	add_skills(id)

	puts "Attacks:"
	add_attacks(id)

	puts "Special Attacks:"
	add_special_attacks(id)

	puts "Items:"
	add_items(id)

	return id
end

def add_languages(id)
	list = gets.chomp.gsub(/, +/, ",").split(",")
	list = list.map{|item| lookup_language(item)}.select{|item| item}
	$conn.query("INSERT INTO c_langs (cid, language) VALUES #{list.map{|item| "(#{id}, #{item})"}.join(", ")}") if list.length > 0
end

def add_feats(id)
	list = gets.chomp.gsub(/, +/, ",").split(",")
	list = list.map{|item| lookup_feat(item)}.select{|item| item}
	$conn.query("INSERT INTO c_feats (cid, feat) VALUES #{list.map{|item| "(#{id}, #{item})"}.join(", ")}") if list.length > 0
end

def add_skills(id)
	list = gets.chomp.gsub(/, +/, ",").split(",")
	list = list.map{|item| parse_skill(item)}.select{|item| item}
	$conn.query("INSERT INTO c_skills (cid, skill, modifier) VALUES #{list.map{|(skill, modifier)| "(#{escape(id)}, #{escape(skill)}, #{escape(modifier)})"}.join(", ")}") if list.length > 0
end

def parse_skill(skill)
	pat = /(.*[^ +0-9]) *((?:\+|-)?[0-9]+)?/
	match = skill.match(pat)
	return nil unless match
	list = []
	list[0] = lookup_skill(match[1])
	return nil unless list[0]
	list[1] = match[2]
	list[1] = list[1].to_i if list[1]
	return list
end

def add_items(id)
	list = gets.chomp.gsub(/, +/, ",").split(",")
	list = list.map{|item| parse_item(item)}.select{|item| item}
	$conn.query("INSERT INTO c_items (cid, item, num) VALUES #{list.map{|(item, num)| "(#{escape(id)}, #{escape(item)}, #{escape(num)})"}.join(", ")}") if list.length > 0
end

def parse_item(item)
	pat = /([^{}]*[^ {}])(?: *\{([0-9+\-d]+)\})?/
	match = item.match(pat)
	return nil unless match
	list = []
	list[0] = lookup_item(match[1])
	return nil unless list[0]
	list[1] = match[2]
	list[1] = 1 unless list[1]
	return list
end

def add_special_attacks(id)
	attacks = []
	while ((line = gets) && ((line = line.chomp) != ""))
		attacks.push(line)
	end
	$conn.query("INSERT INTO c_special_attacks (cid, attack) VALUES #{attacks.map{|attack| "(#{id}, #{escape(attack)})"}.join(", ")}") if attacks.length > 0
end

def add_attacks(id)
	num = 0
	attacks = []
	while ((line = gets) && ((line = line.chomp) != ""))
		num += 1
		list = line.gsub(/, +/, ",").split(",")
		for attack in list
			next unless (attack = parse_attack(attack))
			attacks.push([id, num] + attack)
		end
	end
	$conn.query("INSERT INTO c_attacks (cid, attack_num, name, attack_bonus, damage, min_crit, crit_mult, damage_type, special) VALUES #{attacks.map{|attack| "(#{attack.map{|piece| escape(piece)}.join(", ")})"}.join(", ")}") if attacks.length > 0
end

def parse_attack(attack)
	pat = /(.*[^+\-\/ ]) *((?:\+|-)[+\-\/0-9]*) *\(([0-9 \+\-d]*[0-9\+\-]) *(?:\/([0-9]+)[\-–]20)? *(?:\/[x×]([0-9]+))? *(?:\[([^\[\]]*)\])? *(?:plus +([^)]+))?\)/
	list = attack.scan(pat)
	return nil unless list
	return nil unless list.length > 0
	list = list[0]
	list[3] = list[3].to_i if list[3]
	list[4] = list[4].to_i if list[4]
	list[3] = 20 unless list[3]
	list[4] = 2 unless list[4]
	return list
end

def read_int(num = 1, default = nil)
	values = []
	while (values.length < num)
		read = gets.chomp
		values += read.split(" ")
		return default if (read == "" && num == 1)
	end
	ret = []
	for i in 0...num
		read = values[i]
		if (read == "" || read == "-" || read == "--")
			ret.push default
		else
			ret.push read.to_i
		end
	end
	return ret[0] if num == 1
	return ret
end

def read_int_type(prompt)
	pat = /(-?[0-9]+)(?: *\/ *(.+))?/
	print prompt
	line = gets
	return [nil, nil] unless line
	line.chomp!
	return [nil, nil] if line == ""
	return read_int_type(prompt) unless match = line.match(pat)
	return [match[1].to_i, match[2]]
end

def read_string
	line = gets
	return nil unless line
	line.chomp!
	return nil if line == ""
	return line
end

def read_float(num = 1, default = nil)
	values = []
	while (values.length < num)
		read = gets.chomp
		values += read.split(" ")
		return default if (read == "" && num == 1)
	end
	ret = []
	for i in 0...num
		read = values[i]
		if (read == "" || read == "-" || read == "--")
			ret.push default
		else
			ret.push read.to_f
		end
	end
	return ret[0] if num == 1
	return ret
end

def read_special_ability
	line = gets
	return nil unless line
	line.chomp!
	return nil if line == ""
	name = line
	text = gets.chomp
	return [name, text]
end

def create_encounter
	chars = {}
	pat = /([^{}]*[^ {}])(?: *\{([0-9+\-d]+)\})?/
	print "Name: "
	name = gets.chomp
	while ((line = gets) && ((line = line.chomp) != ""))
		match = line.match(pat)
		unless match
			puts "Error: failed to parse line"
			next
		end
		id = lookup_character(match[1])
		next unless id
		if match[2]
			chars[id] = match[2]
		else
			chars[id] = "1"
		end
	end
	return false if chars.empty?
	acr = calc_acr(chars)
	return false unless confirm("Average CR: #{acr}. OK?")
	$conn.query("INSERT INTO encounters (name, acr) VALUES (#{escape(name)}, #{escape(acr)})")
	eid = $conn.insert_id
	$conn.query("INSERT INTO e_creatures (eid, creature, num) VALUES #{chars.keys.map{|cid| "(#{escape(eid)}, #{escape(cid)}, #{escape(chars[cid])})"}.join(", ")}")
	return true
end
