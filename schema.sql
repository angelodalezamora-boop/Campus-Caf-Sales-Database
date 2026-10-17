-- Project 2: Campus Cafe Sales Database (SQLite)
-- Normalized to 3NF: lookup tables for categories and payment methods,
-- customers and products stored once, orders split from order_items.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS payment_methods;
DROP TABLE IF EXISTS categories;

CREATE TABLE categories (
    category_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT NOT NULL UNIQUE
);

CREATE TABLE payment_methods (
    payment_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT NOT NULL UNIQUE
);

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name     TEXT NOT NULL,
    customer_type TEXT NOT NULL CHECK (customer_type IN ('Student', 'Faculty', 'Staff', 'Visitor')),
    joined_on     TEXT NOT NULL            -- ISO date YYYY-MM-DD
);

CREATE TABLE products (
    product_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT NOT NULL UNIQUE,
    category_id   INTEGER NOT NULL REFERENCES categories(category_id),
    unit_price    REAL NOT NULL CHECK (unit_price > 0),
    unit_cost     REAL NOT NULL CHECK (unit_cost > 0)
);

CREATE TABLE orders (
    order_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id   INTEGER NOT NULL REFERENCES customers(customer_id),
    payment_id    INTEGER NOT NULL REFERENCES payment_methods(payment_id),
    ordered_at    TEXT NOT NULL            -- ISO datetime YYYY-MM-DD HH:MM
);

CREATE TABLE order_items (
    item_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id      INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    INTEGER NOT NULL REFERENCES products(product_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    unit_price    REAL NOT NULL            -- price at time of sale
);

CREATE INDEX idx_orders_date      ON orders(ordered_at);
CREATE INDEX idx_orders_customer  ON orders(customer_id);
CREATE INDEX idx_items_order      ON order_items(order_id);
CREATE INDEX idx_items_product    ON order_items(product_id);
