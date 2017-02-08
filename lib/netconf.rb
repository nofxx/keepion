require 'erb'
require 'fileutils'

# Bind class for ERB configs... need this?
class BindMe
  def initialize(essid, password)
    @essid = essid
    @password = password
  end

  def bind
    binding
  end
end

#
# Configure Linux Network
#
module Netconf
  # Conf templates
  CONF = File.join(File.dirname(__FILE__), '..', 'conf').freeze
  # systemd network
  SYSD = '/etc/systemd/network'.freeze

  FILES = {
    'eth0.network' => "#{SYSD}/eth0.network",
    'wlan0.network.client' => "#{SYSD}/wlan0.network",
    'wpa_supplicant@wlan0.service' => '/etc/systemd/system/'
  }.freeze

  class << self

    def start_services
      [:resolved, :networkd].each do |serv|
        `systemctl enable systemd-#{serv}`
        `systemctl start systemd-#{serv}`
      end
    end

    def install_client
      FILES.each do |file, path|
        puts "Copying #{file} -> #{path}"
        FileUtils.cp(File.join(CONF, file), path)
      end
      start_services
    end

    def install_host
      FileUtils.cp(File.join(CONF, 'wlan0.network.host'),
                   "#{SYSD}/wlan0.network")
      start_services
    end

    def connect(essid, password)
      puts "Connect! #{essid}..."
      vars = BindMe.new(essid, password)
      conf = ERB.new(File.read(File.join(CONF, 'wpa_supplicant.conf.erb')))
      File.write('/etc/wpa_supplicant/wpa_supplicant.conf',
                 conf.result(vars.bind))
      install_client
      start_client!
    end

    def hostap(essid, password)
      puts "HostAP! #{essid}"
      vars = BindMe.new(essid, password)
      conf = ERB.new(File.read(File.join(CONF, 'hostapd.conf.erb')))
      File.write('/etc/hostapd/hostapd.conf', conf.result(vars.bind))
      install_host
      start_host!
    end

    def start_client!
      stop_host!
      restart_network!
      ['wpa_supplicant@wlan0.service'].each do |s|
        `systemctl restart #{s}`
        `systemctl enable #{s}`
      end
    end

    def start_host!
      stop_client!
      restart_network!
      [:hostapd, :dnsmasq].each do |s|
        `systemctl restart #{s}`
        `systemctl enable #{s}`
      end
    end

    def stop_client!
      ['wpa_supplicant@wlan0.service'].each do |s|
        `systemctl stop #{s}`
        `systemctl disable #{s}`
      end
    end

    def stop_host!
      [:hostapd, :dnsmasq].each do |s|
        `systemctl stop #{s}`
        `systemctl disable #{s}`
      end
    end

    def restart_network!
      `systemctl daemon-reload`
      `ip route flush 0/0`
      `systemctl restart systemd-networkd`
    end
  end
end

#if __FILE__ == $0
#  Netconf.install
#end
