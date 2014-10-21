def roll(dicestring, avg = false)
	pieces = dicestring.gsub(" ", "").gsub("-", "+-").split("+")
	tot = 0
	for piece in pieces
		next if piece == ""
		mult = 1
		if piece.start_with? "-"
			mult = -1
			piece.slice!(0)
		end
		if piece.include? "d"
			(num, sides) = piece.split("d")
			if num == ""
				num = 1
			else
				num = num.to_i
			end
			sides = sides.to_i
			for i in 0...num
				if (avg)
					tot += mult * (sides + 1) / 2.0
				else
					tot += mult * (rand(sides) + 1)
				end
			end
		else
			tot += mult * piece.to_i
		end
	end
	tot
end

def escape(string)
	return "TRUE" if string == true
	return "FALSE" if string == false
	return "NULL" unless string
	return string.to_s if string.is_a? Integer
	return string.to_s if string.is_a? Float
	return "'#{string.to_s.gsub("'", "\\\\'")}'"
end

def convert_float(value)
	return nil unless value
	return value.to_f
end

def convert_int(value)
	return nil unless value
	return value.to_i
end

def load_cr_xp
	$cr_xp = {0.125 => 50, 0.166 => 65, 0.25 => 100, 0.333 => 135, 0.5 => 200, 1 => 400, 2 => 600, 3 => 800, 4 => 1200, 5 => 1600, 6 => 2400, 7 => 3200, 8 => 4800, 9 => 6400, 10 => 9600, 11 => 12800, 12 => 19200, 13 => 25600, 14 => 38400, 15 => 51200, 16 => 76800, 17 => 102400, 18 => 153600, 19 => 204800, 20 => 307200, 21 => 409600, 22 => 614400, 23 => 819200, 24 => 1228800, 25 => 1638400}
end

load_cr_xp

def get_xp(cr)
	return $cr_xp[cr] if $cr_xp.has_key?(cr)
	crs = $cr_xp.keys.sort
	low = 0
	high = 0
	for value in crs
		high = value
		break if (high > cr)
		low = high
	end
	lowx = $cr_xp[low]
	highx = $cr_xp[high]
	xp = lowx + (highx - lowx) * (cr - low) * 1.0 / (high - low)
end

def get_cr(xp)
	return $cr_xp.key(xp) if $cr_xp.has_value?(xp)
	xps = $cr_xp.values.sort
	lowx = 0
	highx = 0
	for value in xps
		highx = value
		break if (highx > xp)
		lowx = highx
	end
	low = $cr_xp.key(lowx)
	high = $cr_xp.key(highx)
	xp = low + (high - low) * (xp - lowx) * 1.0 / (highx - lowx)
end

def calc_acr(hash)
	return get_cr(hash.keys.map{|cid| get_xp(Character.new(cid).cr) * roll(hash[cid], true)}.inject(:+))
end
