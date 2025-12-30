# Assumptions

1. An order marked as `IsReturned = TRUE` is considered fully returned.
2. Revenue calculations exclude returned orders unless explicitly stated.
3. Product price is assumed to be constant and stored in the `products` table.
4. Each `OrderID` represents a single customer transaction.
5. Customers with only one order are treated as inactive customers.
6. Discount data is not available; hence pricing analysis is based on listed prices.
7. Time-based analysis uses `OrderDate` as the transaction date.