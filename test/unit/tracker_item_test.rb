# -*- encoding : utf-8 -*-
require 'test_helper'

class TrackerItemTest < ActiveSupport::TestCase

  def setup
    @tracker_item = TrackerItem.find(1)
  end

  test "truth" do
    assert_kind_of TrackerItem,  @tracker_item
  end
end
