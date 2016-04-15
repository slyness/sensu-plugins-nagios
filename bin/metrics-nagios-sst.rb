#! /usr/bin/env ruby
#
# nagios-sst-metrics
#
# DESCRIPTION:
#   This plugin retrives the Nagios Service Status Totals
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: nokogiri
#   gem: httparty
#   gem: sensu-plugin
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright (c) 2016, Aaron Baer, aaron@slyness.org
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'socket'
require 'nokogiri'
require 'httparty'

class SstMetrics < Sensu::Plugin::Metric::CLI::Graphite

  option :host,
         description: 'Nagios instance hostname',
         short: '-h HOSTNAME',
         long:  '--host HOSTNAME',
         default: 'localhost'

  option :user,
         description: 'Nagios instance username',
         short: '-u USER',
         long:  '--user USER',
         default: ''

  option :password,
         description: 'Nagios instance password',
         short: '-p PASSWORD',
         long:  '--password PASSWORD',
         default: ''

  option :mode,
         description: 'http mode',
         short: '-m HTTP',
         long:  '--mode HTTP',
         default: 'http'

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: 'nagios'

  def run
    time = Time.now.to_i

    options = {
       :verify => false,
       :basic_auth => {}
    }

    if config[:user]
      options[:basic_auth].merge!({ :username => config[:user] })
    end

    if config[:password]
      options[:basic_auth].merge!({ :password => config[:password] })
    end

    url = "#{config[:mode]}://#{config[:host]}/cgi-bin/nagios3/status.cgi?hostgroup=all&style=hostdetail"
    page = HTTParty.get(url, options)
    totals = Nokogiri::HTML(page).xpath('//table[@class="serviceTotals"]/tr/td')

    results = {
      :ok => totals[0].text,
      :warning => totals[1].text,
      :unknown => totals[2].text,
      :critical => totals[3].text,
      :pending => totals[4].text
    }

    results.each do |name, value|
      output "#{config[:scheme]}.servicestatus.#{name}", value, time
    end

    ok

  end

end
