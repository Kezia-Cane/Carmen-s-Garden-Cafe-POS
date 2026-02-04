-- Carmen's Garden Cafe POS - Supabase Schema

-- 1. Orders Table
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  order_number INTEGER NOT NULL,
  customer_name TEXT,
  status TEXT NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  tax_amount DECIMAL(10,2) NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  discount_amount DECIMAL(10,2) DEFAULT 0.0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ
);

-- 2. Order Items Table
CREATE TABLE order_items (
  id UUID PRIMARY KEY,
  order_id UUID REFERENCES orders(id),
  menu_item_id UUID NOT NULL,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  modifiers JSONB, -- Stores list of modifiers as JSON
  special_instructions TEXT,
  created_at TIMESTAMPTZ NOT NULL
);

-- 3. Payments Table
CREATE TABLE payments (
  id UUID PRIMARY KEY,
  order_id UUID REFERENCES orders(id),
  payment_method TEXT NOT NULL, -- 'cash', 'card', 'qr_code'
  amount_tendered DECIMAL(10,2) NOT NULL,
  change_amount DECIMAL(10,2) NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);

-- 4. Inventory Transactions Table
CREATE TABLE inventory_transactions (
  id UUID PRIMARY KEY,
  inventory_id UUID NOT NULL, -- UUID string from local DB
  quantity_change INTEGER NOT NULL,
  reason TEXT NOT NULL,
  notes TEXT,
  is_synced INTEGER DEFAULT 1, -- Already synced if landing here
  created_at TIMESTAMPTZ NOT NULL
);

-- 5. Inventory Table (Optional - for simple cloud tracking)
CREATE TABLE inventory (
  id UUID PRIMARY KEY,
  menu_item_id UUID NOT NULL,
  current_stock INTEGER NOT NULL,
  low_stock_threshold INTEGER DEFAULT 5,
  updated_at TIMESTAMPTZ NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

-- Create Policies (Allow public insert/select for now - restrictive in production)
-- Note: In a real app, you'd want authenticated users only. 
-- Since we are using the Anon Key for a simple POS, we allow public access.

CREATE POLICY "Allow public insert orders" ON orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public select orders" ON orders FOR SELECT USING (true);
CREATE POLICY "Allow public update orders" ON orders FOR UPDATE USING (true);

CREATE POLICY "Allow public insert items" ON order_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public select items" ON order_items FOR SELECT USING (true);

CREATE POLICY "Allow public insert payments" ON payments FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public select payments" ON payments FOR SELECT USING (true);

CREATE POLICY "Allow public insert inventory_transactions" ON inventory_transactions FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public select inventory_transactions" ON inventory_transactions FOR SELECT USING (true);

CREATE POLICY "Allow public insert inventory" ON inventory FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public select inventory" ON inventory FOR SELECT USING (true);
CREATE POLICY "Allow public update inventory" ON inventory FOR UPDATE USING (true);
