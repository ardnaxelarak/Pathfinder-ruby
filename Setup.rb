require_relative 'Conditions'
require 'mysql'

$conn = Mysql.new("localhost", "ruby_user", "dNLe7cncmWcbYDdU", "pathfinder_info")
$cond = Conditions.new

$dead = $cond.from_name("Dead")
$dying = $cond.from_name("Dying")
$disabled = $cond.from_name("Disabled")
$stable = $cond.from_name("Stable")
$staggered = $cond.from_name("Staggered")
