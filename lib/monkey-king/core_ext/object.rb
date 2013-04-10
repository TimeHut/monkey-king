Object.class_eval do

	def is_one_of? classes
		(classes || []).each {|c| return true if self.is_a?(c)}
		false
	end
	
end