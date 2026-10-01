# Usage:
#   invoice = Invoice.create(invoice_total: 200.00)
#   invoice.record_payment(100.00, :charge)
class Invoice < ApplicationRecord
  attribute :invoice_total, CentsType.new

  has_many :payments, dependent: :restrict_with_error

  validates :invoice_total, numericality: { greater_than: 0 }

  def amount_owed
    invoice_total.to_d - payments.sum(:amount)
  end

  def fully_paid?
    amount_owed <= 0
  end

  def record_payment(amount, payment_method)
    with_lock do
      payments.create(amount: amount, payment_method: payment_method)
    end
  end
end
