# -*- encoding : utf-8 -*-
require 'test_helper'

class FaqEntryTest < ActiveSupport::TestCase

  def setup
    @faq_entry = FaqEntry.find(1)
  end

  test "truth" do
    assert_kind_of FaqEntry,  @faq_entry
  end
end
