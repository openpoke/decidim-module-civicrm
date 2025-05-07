# frozen_string_literal: true

shared_context "with stubs example api v4" do
  let(:url) { "https://api.example.org/" }
  let(:http_status) { 200 }
  let(:http_method) { :any }
  let(:data) do
    {
      "values" => [],
      "entity" => "",
      "action" => "",
      "version" => 4,
      "count" => 0,
      "countFetched" => 0,
      "countMatched" => 0
    }
  end
  let(:params) do
    {}
  end

  let(:entity) { "" }
  let(:action) { "" }

  before do
    allow(Decidim::Civicrm::Api).to receive(:version).and_return("4")
    allow(Decidim::Civicrm::Api).to receive(:url).and_return(url)
    stub_request(http_method, /api\.example\.org/)
      .to_return(status: http_status, body: data.to_json, headers: {})
  end
end

shared_examples "returns mapped array ids v4" do |property|
  before do
    allow(Decidim::Civicrm::Api).to receive(:version).and_return("4")
  end
  it "returns an Array with the result" do
    expect(subject.result).to be_a Array
    expect(subject.result).to eq(data["values"].map { |v| v[property].to_i })
  end
end
