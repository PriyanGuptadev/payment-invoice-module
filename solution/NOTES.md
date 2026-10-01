# Notes

The original code wouldn't have run. The models didn't inherit from
`ApplicationRecord`, `attr_accessible` went away in Rails 4, the `message:`
option was outside the inclusion hash, and `METHODS.value` isn't a method.
`Payment` had `has_one :invoice` even though the foreign key is on payments,
so I changed it to `belongs_to`.

There were some logic bugs as well. `fully_paid?` returned the opposite of what
it should, and `amount_owed` summed `amount_paid`, a column that doesn't exist.
The before_create callback on `Invoice` multiplied the total by 100 and then
did nothing with the result. `payment_method` looked up the hash by key when it
needed to look up by value (`METHODS.key`). The payment method ID was also set
in `before_create`, which runs after validation, so every payment would have
failed validation.

For money, I added a custom attribute type in `app/types/cents_type.rb` and
used it for `invoice_total` and `amount`. You read, write and query in dollars,
and the database stores cents. I first tried doing the conversion in the
setters, but the getters still returned cents, so
`invoice.update(invoice_total: invoice.invoice_total)` would multiply the total
by 100. A type handles both directions in one place. It uses BigDecimal
because `(0.29 * 100).to_i` is 28 with floats.

On payments, I replaced `raw_payment_method` with a `payment_method=` writer
that matches the reader. A bad method puts the error on `payment_method`, since
that's what the caller passed in. Amounts have to be positive and can't be more
than what's still owed. `record_payment` returns the payment so you can check
`errors`. It takes a lock on the invoice first, so two payments made at the
same moment can't both get past the overpayment check. If you call
`Payment.create` directly you don't get the lock, so go through
`record_payment`.

Payments can't be edited once they're saved, so the overpayment check only has
to run on create. If a payment is wrong, you add a new one. Also,
`Invoice.new.fully_paid?` used to blow up on the nil total. Now nil counts as
zero. I used `to_d` for that instead of `to_i`, because the total is in dollars
now and `to_i` would drop the cents.

The model specs cover 0.29 rounding, `fully_paid?`, overpayment, an unknown
payment method, and zero, negative and missing amounts.

Some things I thought about and left out:

- An enum for payment methods. It would mean a different API (`cash?`, raising
  on unknown values), and the hash works fine.
- A cached `amount_paid` column to avoid a SUM query per invoice. That's more
  state to keep in sync, and nothing here is big enough to need it.
- DB constraints (foreign key, NOT NULL, `CHECK (amount > 0)`). Those belong in
  a migration, which isn't part of this exercise.
- Rejecting fractions of a cent. Right now they get rounded without a warning,
  so 10.005 is stored as 1001.
