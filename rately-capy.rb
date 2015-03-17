require 'bundler'
Bundler.require

require 'capybara/rspec'
require 'capybara/poltergeist'
require 'logger'

Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist

es_url = "http://activity_tracker:Act1v1tyTrack3r@ec2-54-234-209-191.compute-1.amazonaws.com:8080/tracked_activities_production/users_product/_search"

describe "Rately xpath tester", :type => :feature do

  before :all do
    page.driver.options[:js_errors] = false
    page.driver.options[:logger] = File.open("/dev/null",'a')
    page.driver.options[:phantomjs_logger] = File.open("/dev/null",'a')
    page.driver.options[:timeout] = 15
  end

  resp = RestClient.post es_url, {
    size: 0,
    aggs: {
      urls: {
        terms: {
          field: "domain.raw",
          size: 5000
        }
      }
    }
  }.to_json

  data = JSON.parse resp.to_str
  domains = data['aggregations']['urls']['buckets'].map{|h| h['key']}

  domains.each do |domain|

    resp = RestClient.post es_url, {
      size: 10,
      filter: {
        term: {
          :"domain.raw" => domain
        }
      },
      _source: ["base_url"],
      sort: [{created_at: "desc"}]
    }.to_json  

    data = JSON.parse resp.to_str
    urls = data['hits']['hits'].map{|h| h['_source']['base_url']}

    urls.uniq[0..3].each do |url|

      it "tests the tracker on #{url}" do

        load_tries = 0

        begin

          visit(url)

          puts url, page.status_code

        rescue Capybara::Poltergeist::TimeoutError => e

          puts e, url
          page.driver.restart
          load_tries += 1
          retry if load_tries < 5

        rescue Capybara::Poltergeist::JavascriptError => e
          puts e

        end

        expect(page.status_code).not_to be(404)

        execute_script(%|
          script = document.createElement('script')
          script.src = window.location.protocol + "//rately.com/api/products/" + window.location.host.replace(/^www\./,'') + "/tracker.js"
          script.async = false
          document.head.appendChild(script)
        |)

        json = nil
        begin
          while load_tries < 10 && (json.nil? || json.empty?) do
            puts "json", json = evaluate_script("JSBridge_JSON")
            load_tries += 1
            sleep 0.4
          end
        rescue Capybara::Poltergeist::JavascriptError => e
          puts "Waiting for JSBridge_JSON", e.message
          sleep 1
          load_tries += 1
          retry if load_tries < 10
        end

        expect(json).not_to be_empty

        data = JSON.parse(json)
        product = data["product"]

        expect(product["title"]).not_to be_empty
        expect(product["image_url"]).not_to be_empty

      end

    end

  end

end