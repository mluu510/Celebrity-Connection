require 'sqlite3'
require 'set'
require 'debugger'

class Node
	attr_reader :val, :parent
	def initialize(val, parent = nil)
		@val, @parent = val, parent
	end

	def ==(other_node)
		self.val == other_node.val
	end

	def to_s
		self.val
	end
end


def celeb_friends?(celeb1, celeb2)
	# Use BFS to find if two celeb have have a connection
	first_node = Node.new(celeb1)

	open = [first_node]
	closed = Set.new

	until open.empty?
		celeb_node = open.shift
		closed << celeb_node.val

		# Get list of costars
		costars = costars_of(celeb_node.val)

		costars.each do |costar|
			# Check if costar is the target
			if costar == celeb2
				puts "Searched #{closed.count} times."
				return construct_path(Node.new(costar, celeb_node))
			end
	
			open << Node.new(costar, celeb_node) unless closed.include?(costar)
					
		end

		if closed.count % 1000 == 0
			puts "Searching..."
		end

	end
	puts "Couldn't find a connection between #{celeb1} and #{celeb2}. Searched #{closed.count} times."
	nil
end

def costars_of(celeb)
	db = SQLite3::Database.new('movie.db')

	# create query to finding the costars
	# find all movies the actor was in
	query = <<-SQL
		SELECT actor.name
		FROM movie JOIN casting ON movie.id = casting.movieid JOIN actor ON casting.actorid = actor.id
		WHERE movie.id IN (
			SELECT movie.id
			FROM movie JOIN casting ON movie.id = casting.movieid JOIN actor ON casting.actorid = actor.id
			WHERE actor.name = ?
			) AND actor.name != ?
	SQL
	rows = db.execute(query, celeb, celeb)
	db.close
	costars = Set.new
	rows.each do |row|
		costars << row.first
	end
	costars
end

def construct_path(end_node)
	out = []
	curr_node = end_node
	while curr_node.parent
		out.unshift(curr_node.val)
		curr_node = curr_node.parent
	end
	out.unshift(curr_node.val)
	puts "#{out.count} degrees of seperation."
	out
end

def random_celebs(n)
	db = SQLite3::Database.new('movie.db')

	query = <<-SQL
		SELECT actor.name
		FROM actor
	SQL

	celebs = db.execute(query).sample(n).flatten
	db.close
	celebs
end

random_celebs = random_celebs(2)
puts "Is #{random_celebs.first} connected to #{random_celebs.last}?"
p celeb_friends?(*random_celebs)