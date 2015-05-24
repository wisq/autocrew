require 'minitest_helper'
require 'autocrew/contact'

module Autocrew
  class ContactTest < Minitest::Test
    test "TMA with two observers" do
      contact = Contact.new  # Travelling northeast at 6 knots
      ship1 = mock  # 10 nmi north of contact, travelling east at 5 knots
      ship2 = mock  # 10 nmi south of contact, travelling west at 5 knots

      time1 = GameTime.parse('00:00')
      contact.observations << Contact::Observation.new(ship1, time1, 180.0)
      contact.observations << Contact::Observation.new(ship2, time1,   0.0)

      time2 = GameTime.parse('01:00')
      contact.observations << Contact::Observation.new(ship1, time2, 187.49401888493406)
      contact.observations << Contact::Observation.new(ship2, time2,  32.98121264223171)

      contact.solve
    end
  end
end
