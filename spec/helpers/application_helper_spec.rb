require 'spec_helper'

describe ApplicationHelper do

  describe '#full_title'do

    it 'includes the page title' do
      full_title("About").should =~ /About/
    end

    it 'includes the base title' do
      full_title("Contact").should =~ /Playground Breakable Toy/
    end

    it 'does not include a separator when page title is empty' do
      full_title("").should_not =~ /\|/
      full_title(nil).should_not =~ /\|/
    end

  end

end
