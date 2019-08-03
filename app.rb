# frozen_string_literal: true
Encoding.default_external = 'UTF-8'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra-websocket'
require 'json'

require 'net/http'
require 'uri'
require 'thread/pool'
require 'timers'
require 'thwait'

def get_ip(target)
  ping = `ping -c 1 -t 1 #{target}`
  firstline = ping.split("\n")[0]
  return nil if firstline == nil
  firstline[/\((.*?)\)/, 1]
end

def get_docker_stats(targets)
  stats = []
  threads = []

  targets.each{|t|
    threads << Thread.new {
      raw_stats = `#{t[:command]} stats --no-stream #{t[:name]}`
      begin
        raw_stat = raw_stats.split("\n")[1]
        stat = raw_stat.split(" ")
        {name:stat[1], cpu:stat[2].gsub('%', ''), mem:stat[6].gsub('%', ''), time:Time.now.iso8601}
      rescue
      end
    }
  }
  ThreadsWait.all_waits(*threads){ |th|
    stats << th.value
  }
  stats
end

##
# Server program
class App < Sinatra::Base
  register Sinatra::Reloader
  enable :sessions
  set :bind, '0.0.0.0'# 外部アクセス可
  set :port, 3001
  set :sockets, []

  def initialize
    super
    @mon_targets = [
      # { name: 'cube_adapter', command: 'docker -H=sudarepi-a.local:80', host:"sudarepi-a.local", ip:""},
      # { name: 'xproxy', command: 'docker -H=sudarepi-a.local:80', host:"sudarepi-a.local", ip:""},
      # { name: 'demos', command: 'docker -H=sudarepi-b.local:80', host:"sudarepi-b.local", ip:""},
      # { name: 'sudare_sim', command: 'docker -H=sudarepi-c.local:80', host:"sudarepi-c.local", ip:""},
      { name: 'cube_adapter', command: 'docker', host:"sudarepi-a.local", ip:""},
      { name: 'xproxy', command: 'docker', host:"sudarepi-a.local", ip:""},
      { name: 'demos', command: 'docker', host:"sudarepi-b.local", ip:""},
      { name: 'sudare_sim', command: 'docker', host:"sudarepi-c.local", ip:""},
    ]

    @mon_targets.each {|t|
      t[:ip] = get_ip(t[:host])
    }

    timers = Timers::Group.new
    timers.every(3) {
      stat = get_docker_stats(@mon_targets).to_json
      settings.sockets.each {|s|
        s.send stat
      }
    }
    print "async starting"
    Thread.new do
      loop{
        timers.wait
      }
    end
    print "async started.."
  end

  get '/' do
    haml :index, locals: { title: 'Docker Container Monitor' }
  end
  get '/containers' do
    @mon_targets.to_json
  end
  get '/ws' do
    if request.websocket?
      request.websocket do |ws|
        ws.onopen do
          settings.sockets << ws
        end
        ws.onclose do
          settings.sockets.delete(ws)
        end
      end
    end
  end
end
