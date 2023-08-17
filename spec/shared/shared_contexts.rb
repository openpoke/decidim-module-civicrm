# frozen_string_literal: true

shared_context "with stubs example api" do
  let(:url) { "https://api.example.org/" }
  let(:http_method) { :get }
  let(:http_status) { 200 }
  let(:data) do
    {
      "values" => [],
      "is_error" => 0,
      "version" => 3,
      "count" => 0
    }
  end
  let(:params) do
    {}
  end
  let(:return_data) do
    [{
      status: http_status,
      body: data.to_json,
      headers: {}
    }]
  end

  before do
    allow(Decidim::Civicrm::Api).to receive(:url).and_return(url)
    stub_request(http_method, /api\.example\.org/)
      .to_return(return_data)
  end
end

shared_examples "returns mapped array ids" do |property|
  it "returns an Array with the result" do
    expect(subject.result).to be_a Array
    expect(subject.result).to eq(data["values"].map { |v| v[property].to_i })
  end
end
