class TopContainer
  attr_reader :indicator
  attr_reader :uri
  def initialize(hsh)
    @indicator = hsh["indicator_u_icusort"].to_i
    @uri = hsh["uri"]
  end
end
