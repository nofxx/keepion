#!/usr/bin/env ruby
require 'sinatra'
require 'slim'
require_relative 'lib/iwlist'
require_relative 'lib/netconf'

# configure { set server: :puma }

class Keepion < Sinatra::Base
  set environment: :production, port: 80, server: :puma
  WLAN = 'wlan0'.freeze

  get '/' do
    get_sysinfo
    @list = IWList.scan(WLAN)
    slim :index
  end

  post '/connect' do
    if (@essid = params[:essid])
      Netconf.install
      Netconf.connect(params[:essid], params[:password])
    end
    slim :connect
  end

  post '/hostap' do
    if (params[:essid] && params[:password])
      @essid = params[:essid]
      Netconf.hostap(params[:essid], params[:password])
    end
    get_sysinfo
    slim :hostap
  end

  private

  def get_sysinfo
    @data = "KeePion! #{`uname -a`}"
    @wlan = `iwconfig #{WLAN}`
    @ipaddr = `ip addr`
  end
end

if __FILE__ == $0
  Keepion.run!
end
