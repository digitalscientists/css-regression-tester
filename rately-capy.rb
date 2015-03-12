require 'bundler'
Bundler.require

require 'capybara/rspec'
require 'capybara/poltergeist'

Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist

es_url = "http://activity_tracker:Act1v1tyTrack3r@ec2-54-234-209-191.compute-1.amazonaws.com:8080/tracked_activities_production/products/_search"

describe "Rately xpath tester", :type => :feature do

  before :all do
    page.driver.options[:js_errors] = false

      # "filter": {
      #   "term": {
      #     "domain.raw": "macys.com"
      #   }
      # },

  end

  resp = RestClient.post es_url, {
    size: 10,
    _source: ["base_url"],
    sort: [{created_at: "desc"}]
  }.to_json  

  data = JSON.parse resp.to_str
  @urls = data['hits']['hits'].map{|h| h['_source']['base_url']}

  @urls.each do |url|

    it "tests the tracker on #{url}" do

      visit(url)

      execute_script(%|
        script = document.createElement('script')
        script.src = window.location.protocol + "//rately.com/api/products/" + window.location.host.replace(/^www\./,'') + "/tracker.js"
        document.head.appendChild(script)
      |)

      sleep 2

      json = evaluate_script("JSBridge_JSON")

      expect(json).not_to be_empty

      data = JSON.parse(json)
      product = data["product"]

      expect(product["title"]).not_to be_empty
      expect(product["image_url"]).not_to be_empty

    end

  end

end