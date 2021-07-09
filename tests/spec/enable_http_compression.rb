require 'net/http'

feature "Change http compression" do
	after(:all) do
                set_config "http.compression": "false"
                wait_for_nextcloud
	end

	scenario "compression" do
                set_config "http.compression": "true"
                wait_for_nextcloud

		assert_apache_compression
	end

	protected

	def assert_apache_compression
		# Verify that Apache is returning compressed reponses
		expect(nextcloud_response["content-encoding"]).to eq "br"
	end


	def nextcloud_response(url: "http://localhost")
		return Net::HTTP.get_response(URI(url))
	end
end
