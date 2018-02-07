require 'sinatra'
require 'yaml'
require 'redis'

CONFIG = YAML::load_file("config.yml")
REDIS = Redis.new(host: CONFIG["redis_host"])
THIS_NODE_NAME = CONFIG["node_name"]
NODES = CONFIG["node_names"]

if CONFIG["auth"] && CONFIG["auth"]["username"] && CONFIG["auth"]["password"]

  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    username ==  CONFIG["auth"]["username"] and password == CONFIG["auth"]["password"]
  end

end


get '/' do
  this_node_count = REDIS.get(THIS_NODE_NAME)
  if this_node_count.nil?
    # Set the first count
    REDIS.set(THIS_NODE_NAME, 1) 
  else
    # Increment count
    this_node_count = this_node_count.to_i
    this_node_count += 1 
    REDIS.set(THIS_NODE_NAME, this_node_count)
  end
  message = <<-EOF
    Hello from #{CONFIG['node_name']}!
    The request counts for each web node are:
  EOF
  NODES.each do |node_name| 
    count = REDIS.get(node_name) || "0"
    message << "#{node_name} => #{count}"
  end
  message
end
