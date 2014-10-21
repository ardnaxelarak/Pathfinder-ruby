require_relative 'Setup'
require_relative 'Attacks'
require_relative 'Functions'
require_relative 'Item'

class Character
	attr_reader :name, :cr, :str, :dex, :con, :int, :wis, :cha, :bab,
				:initiative, :speed, :air_speed, :air_maneuver,
				:attacks, :hp_max, :ac, :touch_ac, :flat_footed_ac,
				:dr, :dr_bypass, :fast_healing, :regeneration, 
				:regeneration_bypass, :sr, :ferocity,
				:cur_init, :damage, :items, :conditions, :url,
				:regen_block, :space, :reach
	attr_reader	:dead, :dying, :disabled, :stable
	attr_accessor :verbose, :cname
	def initialize(id = nil, cname = nil, verbose = false)
		return unless id
		@verbose = verbose
		@id = id
		res = $conn.query("SELECT name, cr, strength, dexterity, constitution, intelligence, wisdom, charisma, base_attack_bonus, initiative, speed, fly_speed, fly_maneuver, swim_speed, climb_speed, burrow_speed, space, reach, ac, touch_ac, flat_footed_ac, hp, ferocity, fast_healing, regeneration, regeneration_bypass, fort, ref, will, dr, dr_bypass, sr, url FROM characters WHERE id = #{id}")
		return unless row = res.fetch_row
		@name = row.shift
		if cname
			@cname = cname
		else
			@cname = name
		end
		@cr = convert_float(row.shift)
		@str = convert_int(row.shift)
		@dex = convert_int(row.shift)
		@con = convert_int(row.shift)
		@int = convert_int(row.shift)
		@wis = convert_int(row.shift)
		@cha = convert_int(row.shift)
		@bab = row.shift
		@initiative = convert_int(row.shift)
		@speed = convert_int(row.shift)
		@fly_speed = convert_int(row.shift)
		@fly_maneuver = row.shift
		@swim_speed = convert_int(row.shift)
		@climb_speed = convert_int(row.shift)
		@burrow_speed = convert_int(row.shift)
		@space = convert_int(row.shift)
		@reach = convert_int(row.shift)
		@ac = convert_int(row.shift)
		@touch_ac = convert_int(row.shift)
		@flat_footed_ac = convert_int(row.shift)
		@hp_max = roll(row.shift)
		@ferocity = row.shift.to_i > 0
		@fast_healing = convert_int(row.shift)
		@regeneration = convert_int(row.shift)
		@regeneration_bypass = row.shift
		@fort = convert_int(row.shift)
		@ref = convert_int(row.shift)
		@will = convert_int(row.shift)
		@dr = row.shift
		@dr_bypass = row.shift
		@sr = convert_int(row.shift)
		@url = row.shift

		@skills = {}
		res = $conn.query("SELECT skill, modifier FROM c_skills WHERE cid = #{id}")
		while ((row = res.fetch_row) != nil)
			@skills[row[0].to_i] = row[1].to_i
		end

		@attacks = Attacks.new(id)

		@items = get_character_items(id)

		@damage = 0
		@regen_block = 0
		@conditions = []
	end

	def roll_init
		@cur_init = rand(20) + 1 + @initiative
	end

	def add_condition(cond)
		if (cond.is_a?(Condition))
			c = cond
		elsif (cond.is_a?(String))
			c = $cond.from_name(cond)
		elsif (cond.is_a?(Fixnum))
			c = $cond[cond]
		else
			c = nil
		end
		case c
		when $dead
			@dead = true
		when $dying
			@dying = true
		when $stable
			@stable = true
		when $disabled
			@disable = true
		end
		@conditions.push(c) if c && !@conditions.include?(c)
	end

	def remove_condition(cond)
		if (cond.is_a?(Condition))
			c = cond
		elsif (cond.is_a?(String))
			c = $cond.from_name(cond)
		elsif (cond.is_a?(Fixnum))
			c = $cond[cond]
		else
			c = nil
		end
		case c
		when $dead
			@dead = false
		when $dying
			@dying = false
		when $stable
			@stable = false
		when $disabled
			@disable = false
		end
		@conditions.delete(c) if c
	end

	def find_modifiers
		@str_mod = @str / 2 - 5 if str
		@dex_mod = @dex / 2 - 5 if dex
		@con_mod = @con / 2 - 5 if con
		@int_mod = @int / 2 - 5 if int
		@wis_mod = @wis / 2 - 5 if wis
		@cha_mod = @cha / 2 - 5 if cha
	end

	def kill
		add_condition($dead)
		remove_condition($dying)
		remove_condition($disabled)
		remove_condition($stable)
	end

	def start_dying
		return if dead
		add_condition($dying)
		remove_condition($disabled)
		remove_condition($stable)
	end

	def disable
		return if dead
		return if dying
		add_condition($disabled)
		remove_condition($stable)
	end

	def stabalize
		return if dead
		remove_condition($dying)
		add_condition($stable)
	end

	def take_damage(amount, bypass_dr = :prompt, suppress_regen = :prompt)
		return if dead
		return if amount <= 0
		if dr && dr > 0
			if !dr_bypass || (bypass_dr == :prompt && prompt("Bypass DR (#{dr_bypass})?", false)) || bypass_dr == true
				amount -= dr
				amount = 0 if amount < 0
				puts "DR reduces damage to #{amount}" if verbose
				return if amount < 0
			end
		end
		if regeneration && regeneration > 0 && regen_block == 0
			if regeneration_bypass && (suppress_regen == :prompt && prompt("Suppress regeneration (#{dr_bypass})?", false)) || bypass_dr == true
				@regen_block = 1
				puts "Regeneration is suppressed for #{cname}" if verbose
				return if amount < 0
			end
		end
		if (hp - amount <= -con)
			kill
			puts "#{cname} is dead" if verbose
		elsif (hp >= 0 && hp < amount)
			if ferocity
				add_condition($staggered)
				puts "#{cname} is at negative hitpoints and staggered" if verbose
			else
				start_dying
				puts "#{cname} is dying" if verbose
			end
		elsif (hp == amount)
			disable
			puts "#{cname} is disabled" if verbose
		end
		@damage += amount
	end

	def heal(amount)
		return if amount <= 0
		amount = damage if amount > damage
		@damage -= amount
	end

	def apply_healing
		if fast_healing && fast_healing > 0
			amount = fast_healing
			amount = damage if amount > damage
			if amount > 0
				heal(amount)
				puts "#{cname} heals #{amount} from fast healing" if verbose
			end
		end
		if regen_block > 0
			@regen_block -= 1
			puts "Regeneration resumes for #{cname}" if regen_block == 0 && verbose
		elsif regeneration && regeneration > 0
			amount = regeneration
			amount = damage if amount > damage
			if amount > 0
				heal(amount)
				puts "#{cname} heals #{amount} from regeneration" if verbose
			end
		end
	end

	def hp
		return hp_max - damage
	end

	def print_status
		puts "HP: #{hp} / #{hp_max}"
		puts "Speed: #{speed} ft."
		puts "Reach: #{reach} ft." if reach != 5
		puts conditions.join(", ") unless conditions.empty?
		unless attacks.empty?
			puts "Attacks:"
			puts attacks.attack_lines.map{|line| "  #{line}"}.join("\n")
		end
		if items.length > 0
			puts "Items:"
			for item in items
				puts "  #{item}"
			end
		end
		return nil
	end
end
