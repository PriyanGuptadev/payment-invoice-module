class Payment < ApplicationRecord
  METHODS = { cash: 1, check: 2, charge: 3 }.freeze

  attribute :amount, CentsType.new

  belongs_to :invoice

  validates :payment_method, inclusion: { in: METHODS.keys, message: "is not a valid payment method" }
  validates :amount, numericality: { greater_than: 0 }
  validate :not_more_than_amount_owed, on: :create

  def payment_method
    METHODS.key(payment_method_id)
  end

  def payment_method=(method)
    self.payment_method_id = METHODS[method.to_s.to_sym]
  end

  # Saved payments can't be edited, which is why the overpayment check only
  # runs on create.
  def readonly?
    persisted? || super
  end

  private

  def not_more_than_amount_owed
    return if invoice.nil? || amount.nil?

    errors.add(:amount, "is more than the amount owed") if amount > invoice.amount_owed
  end
end
