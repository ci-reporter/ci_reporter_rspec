describe "RSpec example" do
  it "should succeed" do
    true.should be true
    nil.should be_nil
  end

  it "should fail" do
    true.should be false
  end

  it "should be pending"

  describe "nested" do
    it "should succeed" do
      true.should be true
    end
  end
end
