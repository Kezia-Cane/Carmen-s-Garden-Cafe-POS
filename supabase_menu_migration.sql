-- Carmen's Garden Cafe POS - Menu and Activity Log Schema Migration
-- Run this in your Supabase SQL Editor

-- ============================================
-- MENU TABLES (for cloud sync)
-- ============================================

-- 1. Categories Table
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

-- 2. Menu Items Table
CREATE TABLE IF NOT EXISTS menu_items (
  id UUID PRIMARY KEY,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  track_inventory BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

-- Indexes for menu_items
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_available ON menu_items(is_available);

-- 3. Item Modifiers Table
CREATE TABLE IF NOT EXISTS item_modifiers (
  id UUID PRIMARY KEY,
  menu_item_id UUID REFERENCES menu_items(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- 'single_select', 'multi_select'
  options JSONB NOT NULL, -- Array of {name, priceAdjustment}
  is_required BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL
);

-- Index for item_modifiers
CREATE INDEX IF NOT EXISTS idx_modifiers_item ON item_modifiers(menu_item_id);

-- ============================================
-- ACTIVITY LOGS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY,
  event_type TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT,
  description TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL
);

-- Indexes for activity_logs
CREATE INDEX IF NOT EXISTS idx_activity_logs_event ON activity_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON activity_logs(entity_type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created ON activity_logs(created_at);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_modifiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Categories policies
CREATE POLICY "Allow public select categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Allow public insert categories" ON categories FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update categories" ON categories FOR UPDATE USING (true);
CREATE POLICY "Allow public delete categories" ON categories FOR DELETE USING (true);

-- Menu items policies
CREATE POLICY "Allow public select menu_items" ON menu_items FOR SELECT USING (true);
CREATE POLICY "Allow public insert menu_items" ON menu_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update menu_items" ON menu_items FOR UPDATE USING (true);
CREATE POLICY "Allow public delete menu_items" ON menu_items FOR DELETE USING (true);

-- Item modifiers policies
CREATE POLICY "Allow public select item_modifiers" ON item_modifiers FOR SELECT USING (true);
CREATE POLICY "Allow public insert item_modifiers" ON item_modifiers FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update item_modifiers" ON item_modifiers FOR UPDATE USING (true);
CREATE POLICY "Allow public delete item_modifiers" ON item_modifiers FOR DELETE USING (true);

-- Activity logs policies
CREATE POLICY "Allow public select activity_logs" ON activity_logs FOR SELECT USING (true);
CREATE POLICY "Allow public insert activity_logs" ON activity_logs FOR INSERT WITH CHECK (true);
