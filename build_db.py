"""Builds cafe_sales.db from schema.sql and fills it with sample data.

Run:  python build_db.py
The data is generated with a fixed random seed, so every run gives the same result.
The data is SAMPLE data created for this project, not real sales.
"""
import random
import sqlite3
from datetime import date, datetime, timedelta
from pathlib import Path

HERE = Path(__file__).parent
DB = HERE / "cafe_sales.db"
random.seed(2026)

CATEGORIES = ["Coffee", "Non-Coffee Drinks", "Pastries", "Meals", "Snacks"]
PAYMENTS = ["Cash", "GCash", "Maya", "Student ID Wallet"]

# name, category, price, cost
PRODUCTS = [
    ("Americano", "Coffee", 80, 25), ("Cafe Latte", "Coffee", 110, 38),
    ("Caramel Macchiato", "Coffee", 130, 48), ("Iced Coffee", "Coffee", 95, 30),
    ("Milk Tea", "Non-Coffee Drinks", 90, 28), ("Matcha Latte", "Non-Coffee Drinks", 120, 45),
    ("Lemonade", "Non-Coffee Drinks", 70, 18), ("Hot Chocolate", "Non-Coffee Drinks", 100, 32),
    ("Croissant", "Pastries", 75, 30), ("Blueberry Muffin", "Pastries", 65, 24),
    ("Cheesecake Slice", "Pastries", 120, 55), ("Chicken Sandwich", "Meals", 110, 52),
    ("Pasta Carbonara", "Meals", 140, 62), ("Silog Meal", "Meals", 105, 48),
    ("French Fries", "Snacks", 70, 22), ("Nachos", "Snacks", 95, 36),
]

FIRST = ["Angel", "Marco", "Bea", "Carlo", "Dana", "Ethan", "Faith", "Gabriel", "Hannah", "Ian",
         "Jasmine", "Kyle", "Lara", "Miguel", "Nina", "Owen", "Paula", "Rafael", "Sofia", "Tristan"]
LAST = ["Santos", "Reyes", "Cruz", "Bautista", "Garcia", "Mendoza", "Torres", "Flores", "Ramos",
        "Aquino", "Castillo", "Villanueva", "Navarro", "Domingo", "Salazar"]
TYPE_WEIGHTS = [("Student", 70), ("Faculty", 12), ("Staff", 10), ("Visitor", 8)]

# Category popularity by hour (cafe is busiest mid-morning and lunch)
HOUR_WEIGHTS = {7: 4, 8: 8, 9: 10, 10: 8, 11: 10, 12: 14, 13: 12, 14: 8, 15: 8, 16: 6, 17: 3}


def pick_weighted(pairs):
    return random.choices([p[0] for p in pairs], [p[1] for p in pairs])[0]


def main():
    if DB.exists():
        DB.unlink()
    con = sqlite3.connect(DB)
    con.executescript((HERE / "schema.sql").read_text(encoding="utf-8"))
    cur = con.cursor()

    cur.executemany("INSERT INTO categories(name) VALUES (?)", [(c,) for c in CATEGORIES])
    cur.executemany("INSERT INTO payment_methods(name) VALUES (?)", [(p,) for p in PAYMENTS])
    cat_id = {n: i for i, n in cur.execute("SELECT category_id, name FROM categories")}
    pay_id = {n: i for i, n in cur.execute("SELECT payment_id, name FROM payment_methods")}

    cur.executemany(
        "INSERT INTO products(name, category_id, unit_price, unit_cost) VALUES (?,?,?,?)",
        [(n, cat_id[c], p, k) for n, c, p, k in PRODUCTS])
    products = cur.execute("SELECT product_id, name, unit_price FROM products").fetchall()

    start, end = date(2026, 3, 2), date(2026, 9, 30)
    used = set()
    customers = []
    while len(customers) < 120:
        name = f"{random.choice(FIRST)} {random.choice(LAST)}"
        if name in used:
            continue
        used.add(name)
        joined = start + timedelta(days=random.randint(0, 150))
        customers.append((name, pick_weighted(TYPE_WEIGHTS), joined.isoformat()))
    cur.executemany("INSERT INTO customers(full_name, customer_type, joined_on) VALUES (?,?,?)", customers)

    cust_rows = cur.execute("SELECT customer_id, joined_on FROM customers").fetchall()
    pay_names = ["Cash", "GCash", "Maya", "Student ID Wallet"]
    pay_w = [40, 35, 10, 15]
    hours = list(HOUR_WEIGHTS)
    hour_w = list(HOUR_WEIGHTS.values())

    day = start
    while day <= end:
        if day.weekday() < 6:  # closed Sundays
            base = 22 if day.weekday() < 5 else 12
            # Lower traffic during semester break (Jun 1 - Jul 5) and a mild upward trend
            if date(2026, 6, 1) <= day <= date(2026, 7, 5):
                base = int(base * 0.45)
            base = int(base * (1 + (day - start).days / 700))
            for _ in range(max(3, int(random.gauss(base, 3)))):
                eligible = [c for c, j in cust_rows if j <= day.isoformat()]
                if not eligible:
                    continue
                cid = random.choice(eligible)
                hour = random.choices(hours, hour_w)[0]
                ts = datetime(day.year, day.month, day.day, hour, random.randint(0, 59))
                pid = pay_id[random.choices(pay_names, pay_w)[0]]
                cur.execute("INSERT INTO orders(customer_id, payment_id, ordered_at) VALUES (?,?,?)",
                            (cid, pid, ts.strftime("%Y-%m-%d %H:%M")))
                oid = cur.lastrowid
                lunch = 11 <= hour <= 13
                for prod in random.sample(products, k=random.choice([1, 1, 2, 2, 3])):
                    prod_id, pname, price = prod
                    is_meal = pname in ("Chicken Sandwich", "Pasta Carbonara", "Silog Meal")
                    if is_meal and not lunch and random.random() < 0.6:
                        continue
                    qty = random.choices([1, 2, 3], [78, 17, 5])[0]
                    cur.execute("INSERT INTO order_items(order_id, product_id, quantity, unit_price) VALUES (?,?,?,?)",
                                (oid, prod_id, qty, price))
                # remove empty orders created when every item was skipped
                if not cur.execute("SELECT 1 FROM order_items WHERE order_id=?", (oid,)).fetchone():
                    cur.execute("DELETE FROM orders WHERE order_id=?", (oid,))
        day += timedelta(days=1)

    con.commit()
    for t in ["categories", "payment_methods", "customers", "products", "orders", "order_items"]:
        print(f"{t:16}", cur.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0])
    con.close()


if __name__ == "__main__":
    main()
