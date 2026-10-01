require "bigdecimal/util"

# Dollars in Ruby, integer cents in the database. BigDecimal because
# 0.29 * 100 == 28.999999999999996 with floats.
class CentsType < ActiveModel::Type::Value
  def deserialize(cents)
    return if cents.nil?

    cents.to_d / 100
  end

  def serialize(dollars)
    dollars = cast(dollars)
    return if dollars.nil?

    (dollars * 100).to_i
  end

  private

  def cast_value(dollars)
    return if dollars.blank?

    dollars.to_s.to_d.round(2)
  end
end
