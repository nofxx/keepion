#!/usr/bin/ruby
# Copyright (c) 2007 Chris Riddoch
# This code is licensed under the LGPL v2.1.  See the 'LGPL' file in
# the main directory of this project for details.
# This is a class providing access to information about access points
# discovered by the IWList.scan() method.
#
# Perhaps eventually I might put some useful methods here...
class AP
  attr_accessor :cell, :address, :essid, :essid_index, :protocol,
                :mode, :channel, :encrypted, :bitrates, :quality,
                :signal_level, :noise_level, :ie, :last_beacon

  def signal
    return '-' unless quality
    x, y = quality.split('/').map(&:to_i)
    "#{x * 100 / y}%"
  end
end

# This exception class is raised if the interface provided to
# IWList.scan isn't in the form <tt>ethN</tt> or <tt>wlanN</tt>
class InvalidInterface < RuntimeError
end

#
# Reads and parses iwlist output
#
class IWList
  # Runs "<i>iwlist interface scan</i>" in a subshell and returns a list of hashes.
  #
  # The first parameter should be <tt>"ethN"</tt> or <tt>"wlanN"</tt> where N is a number.
  # The second parameter is a hash of options.  The possible keys are:
  #
  #  * :bin - The full path to the iwlist program; defaults to <tt>'/usr/sbin/iwlist'</tt>
  #  * :test_io - An IO instance to read from, instead of running iwlist
  #
  # <b>NOTE!  IWLIST MUST BE RUN AS ROOT.  TREAT USER INPUT WITH CARE.</b>
  # If you get no results, it's probably because you aren't running as root.
  #
  # Raises InvalidInterface exception if the first parameter doesn't look like a
  # reasonable interface.
  def self.scan(interface, options = {})
    # Is someone playing games?
    raise InvalidInterface if interface !~ /^(en|eth|wlan)\d+$/

    iwlist_output = ''
    iwlist_command = options[:bin] || `which iwlist`.chomp

    if options[:test_io] # To allow for testing.
      iwlist_output = options[:test_io].gets(nil)
    else
      puts "#{iwlist_command} #{interface}...."
      IO.popen("#{iwlist_command} #{interface} scan") do |pipe|
        iwlist_output = pipe.gets(nil)
      end
    end

    raise 'IWlist empty!' unless iwlist_output

    aps = iwlist_output.scan(@iwlist_block).map do |m|
      ap = AP.new
      puts "AP #{m}"
      order.each_with_index do |name, i|
        value = m[i]
        # Bitrates is a list of 'number Mb/s;'.
        # This is to simplify the IWList_block regex
        if name == :bitrates
          value = value.scan(%r{[0-9.]+ Mb/s;?})
          value.map! do |rate|
            rate =~ /([0-9.]+)/
            $1.to_f
          end
        end

        # Convert numbers.
        value = value.to_i if value =~ /^(\d+)$/

        ap.send("#{name}=", value)
      end
      ap
    end
    aps
  end

  # The regex used for extracting each AP's data from the output of iwlist.
  @iwlist_block = %r{
  \s+  Cell \s (\d+) \s - \s Address: \s ((?:[A-Z0-9][A-Z0-9]:?)+)
  \s+  Channel:(\d+)
  \s+  Frequency:\d+ .*?
  \s+  Quality=(\d+/\d+) \s .*?
  \s+  Encryption \s key:(on|off)
  \s+  ESSID:"([^"]+)"  (\[\d+\])?
#  \s+  Protocol:([^\n]+)  # Everything up to end of line.
#  \s+  Mode: ([^\n]+)
#  \s+  Bit \s Rates:(.*?)     # This will be parsed out later
#  \s+  Signal \s level:(\d+)
#  \s+  Noise \s level:(\d+)
#  \s+  (IE: .*? )?     # I'll worry about this later.
#  \s+  Extra: \s Last \s beacon: \s (\d+)ms \s ago
  }mx

  # The order of values grouped by the IWList_block regex
  def self.order
    [:cell, :address, :channel, :quality, :encrypted, :essid, :essid_index]
    # :protocol, :mode, :channel,
    # :encrypted, :bitrates, :quality, :signal_level,
    # :noise_level, :ie, :last_beacon]
  end
end

#  A quick test...
# require 'yaml'
# puts IWList.scan("eth1").to_yaml
