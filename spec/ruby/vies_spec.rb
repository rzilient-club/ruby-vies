# frozen_string_literal: true

RSpec.describe Ruby::Vies do
  it "has a version number" do
    expect(Ruby::Vies::VERSION).not_to be nil
  end

  describe "Call Vies using a invalid VAT" do
    it "checks the VAT number and returns an error" do
      resp = Ruby::Vies::Client.new.check_vat_details({ country_code: "FR", vat_number: "0" })
      expect(resp[:valid]).to(be(false))
      expect(resp[:address]).to(be(nil))
      expect(resp[:name]).to(be(nil))
      expect(resp[:vat_number]).to(be(nil))
    end
    it "checks a valid VAT number" do
      resp = Ruby::Vies::Client.new.check_vat_details({ country_code: "FR", vat_number: "881969976" })
      expect(resp[:valid]).to(be(true))
      expect(resp[:address]).to(eq(" 4  RUE DE LA REPUBLIQUE 69001 LYON 1ER   69381    "))
      expect(resp[:name]).to(eq("RZILIENT GROUP"))
      expect(resp[:vat_number]).to(be(nil))
    end
    it "checks the VAT number doesn't belong to EU country" do
      resp = Ruby::Vies::Client.new.check_vat_details({ country_code: "GB", vat_number: "0" })
      expect(resp[:valid]).to(eq(false))
    end
  end
end
