require 'rubygems'
require 'xmpp4r-simple'
require 'gosu'
require 'yaml'

class Jabbersonic < Gosu::Window

  SOUND_ROOT_LOCATION = "/Library/Audio/Apple Loops/Apple/iLife Sound Effects/"
  
  def initialize(user, pass)
    super(100,100, false)
    @im = Jabber::Simple.new(user, pass)
    @sound_store = {}
    @cmds = YAML.load_file(File.dirname(__FILE__) + '/../config.yml')
    start(@cmds["background"])
  end
  
  def update
    @im.received_messages do |msg|
      if msg.body.match(/^stop/)
        stop, cmd = msg.body.split
        break unless @cmds.include? cmd
        if (@cmds[cmd][:type] != :state)
          @im.deliver(msg.from, "error: cannot stop #{cmd} - not a state")
          break
        end
        @im.deliver(msg.from, "stopping #{cmd}...")
        stop(@cmds[cmd])
        @im.deliver(msg.from, "ok")
      else
        cmd = msg.body
        break unless @cmds.include? cmd
        if (@cmds[cmd][:type] == :background)
          @im.deliver(msg.from, "error: cannot control #{cmd} - it's a background state")
          break
        end
        @im.deliver(msg.from, "playing #{msg.body}...")
        start(@cmds[msg.body])
        @im.deliver(msg.from, "ok")
      end
    end
  end

  def stop(sound)
    play(sound, false)
    sleep rand(4) + 2
    sound[:instance1].stop
    sleep rand(4) + 2
    sound[:instance2].stop
  end

  def start(sound)
    sound[:sample] ||= Gosu::Sample.new(self, SOUND_ROOT_LOCATION + sound[:file])
    case true
    when sound[:type] == :event
      play(sound, false)
    when sound[:type] == :state || sound[:type] == :background
      sound[:instance1] = play(sound, true)
      sleep rand(4) + 2
      sound[:instance2] = play(sound, true)
    end
  end
  
  def play(sound, repeating)
    puts "PLAY: #{sound[:file]}"
    sound[:sample].play(sound[:volume] || 1.0, 1.0, repeating)      
  end
end