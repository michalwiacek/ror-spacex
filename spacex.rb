require 'rubygems'
require 'json'
require 'net/http'
require 'time'

rocket_url = 'https://api.spacexdata.com/v2/rockets'
launches_url = 'https://api.spacexdata.com/v2/launches'

rocket_uri = URI(rocket_url)
launches_uri = URI(launches_url)


rocket_response = Net::HTTP.get(rocket_uri)
@rocket_result = JSON.parse(rocket_response)

launches_response = Net::HTTP.get(launches_uri)
launches_result = JSON.parse(launches_response)


def get_result(url)
  uri = URI(url)
  response = Net::HTTP.get(uri)
  result = JSON.parse(response)
end

def yearly_launches_cost(year)
  result = get_result("https://api.spacexdata.com/v2/launches?launch_year=#{year}")
  arr = []
  result.each {|r| arr << r['rocket']['rocket_id']}

  counts = Hash.new 0
  arr.each do |rocket|
    counts[rocket] += 1
  end

  intersection = counts.keys & launch_cost.keys
  c = counts.dup.update(launch_cost)
  inter = {}
  intersection.each { |k| inter[k]=c[k] }

  counts = counts.merge!(inter) { |key, v2, v1| key.nil? ? 0 : v1*v2}

  arr = counts.values.to_a

  puts "#{year} #{arr.sum}"
end

def get_rockets(launches_result)
  rocket_id_name = Hash.new 0
  launches_result.each do |r|
    rocket_id_name[r['rocket']['rocket_id']] = r['rocket']['rocket_name']
  end
  rocket_id_name
end

def launch_cost
  launch_cost = {}
  @rocket_result.each { |r| launch_cost[r['id']] = r['cost_per_launch'] }
  launch_cost
end

def rocket_lauches_cost(launches_result)

  arr = []
  launches_result.each do |c|
    arr << c['rocket']['rocket_id']
  end

  counts = Hash.new 0
  arr.each do |rocket|
    counts[rocket] += 1
  end

  counts.merge!(launch_cost) { |key, v1, v2| v1*v2}
  launches = Hash[get_rockets(launches_result).values.zip(counts.values)]

  launches.each { |key, val| puts "#{key} #{val}"}
end

def launch_count(result)
  arr = []
  result.each do |a|
    launch_time = Time.at(a['launch_date_unix'])
    arr << launch_time.month
  end

  counts = {}
  (1..12).each { |i| counts[i] = 0 }

  arr.each { |month| counts[month] += 1 }
  counts = Hash[counts.sort_by { |key, val| key }]
  1.upto(12) { |a| puts "#{a} #{counts[a]? counts[a] : 0}" }
end


def payload(result)
  @total_payload = 0
  result.each do |a|
    a['payload_weights'].each do |kg|
      @total_payload += kg['kg']
    end
  end
  puts @total_payload
end

launch_count(launches_result)
payload(@rocket_result)
rocket_lauches_cost(launches_result)
(2006..2018).each do |y|
  yearly_launches_cost(y)
end