describe "a passing example" do
  it "passes" do
    true.should be true
  end
end

describe "a failing example" do
  it "fails" do
    true.should be false
  end
end

describe "a pending example" do
  it "is not run"
end

describe "outer context" do
  it "passes" do
    true.should be true
  end

  describe "inner context" do
    it "passes" do
      true.should be true
    end
  end
end
