shared_examples_for "all static pages" do
  it { should have_header(heading) }
  #it { should have_title(text: page_title) }
end

