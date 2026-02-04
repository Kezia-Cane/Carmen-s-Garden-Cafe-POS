# Carmen's Garden POS - Visual Flow Diagrams & Activity Log Reference

---

## 1. COMPLETE APP FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────────────┐
│                          APP START                                  │
└────────────────────────┬────────────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │     SPLASH SCREEN (2-3s)       │
        ├────────────────────────────────┤
        │ • Show logo                    │
        │ • Initialize DB                │
        │ • Load menu & inventory        │
        │ • Check network                │
        │ • Start sync service           │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │   MAIN DASHBOARD (Home)        │
        ├────────────────────────────────┤
        │ Tabs:                          │
        │ [POS] [Orders] [Inv] [Rep] [Log] │
        │                                │
        │ Top Bar: Sync Status + Settings│
        └────┬──────┬──────┬──────┬──────┘
             │      │      │      │
         ┌───▼──┐   │      │      │
         │ TAB 1│   │      │      │
         │ POS  │   │      │      │
         └──────┘   │      │      │
             │      ▼      │      │
             │   ┌──────────────┐ │
             │   │ TAB 2: Orders│ │
             │   └──────────────┘ │
             │      │             │
             │      ▼             │
             │  ┌──────────────┐  │
             │  │ TAB 3:       │  │
             │  │ Inventory    │  │
             │  └──────────────┘  │
             │      │             │
             │      ▼             │
             │   ┌──────────────┐ │
             │   │ TAB 4: Reps  │ │
             │   └──────────────┘ │
             │      │             │
             │      ▼             │
             │  ┌──────────────┐  │
             │  │ TAB 5: Log   │  │
             │  └──────────────┘  │
             │                    │
             ▼
    ┌──────────────────────────────────────┐
    │ TAB 1: POS TERMINAL                  │
    ├──────────────────────────────────────┤
    │ • Browse menu (categories)           │
    │ • Tap item → add to cart             │
    │ • Modify: size, milk, extras         │
    │ • View cart                          │
    │ • Tap "Checkout"                     │
    │ ✓ Log: Order Created                 │
    │         Order #, items, amount       │
    └────────┬────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │ CHECKOUT SCREEN                      │
    ├──────────────────────────────────────┤
    │ • Review items                       │
    │ • Show subtotal + tax                │
    │ • Tap "Pay with Cash"                │
    └────────┬────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │ CASH PAYMENT SCREEN                  │
    ├──────────────────────────────────────┤
    │ • Show order total: $X.XX            │
    │ • Input cash tendered: $Y.XX         │
    │ • Auto-calc change: $Y.XX - $X.XX    │
    │ • Quick buttons: $10, $20, $50, etc  │
    │ • Tap "Complete Payment"             │
    │ ✓ Log: Payment Processed             │
    │         Amount, cash, change         │
    │ ✓ Update: Order → Completed          │
    │ ✓ Log: Order Status Changed          │
    │         Status: pending → completed  │
    └────────┬────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │ PAYMENT CONFIRMATION                 │
    ├──────────────────────────────────────┤
    │ ✓ Payment successful!                │
    │ • Amount: $X.XX                      │
    │ • Change: $Y.YY                      │
    │ • Order #: 145                       │
    │ Tap "OK" → Back to POS               │
    └────────┬────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │ RETURN TO DASHBOARD                  │
    │ (Continue taking more orders)        │
    └──────────────────────────────────────┘
    
    
    PARALLEL FLOWS:
    
    ┌──────────────────────────────────────┐
    │ TAB 2: ORDERS MANAGEMENT             │
    ├──────────────────────────────────────┤
    │ • View all today's orders            │
    │ • Filter by status:                  │
    │   - Pending: waiting to prepare      │
    │   - Preparing: being made            │
    │   - Ready: waiting for customer      │
    │   - Completed: paid & delivered      │
    │ • Tap order → see details            │
    │ • Swipe to change status             │
    │ ✓ Log: Order Status Updated          │
    │         Old → New status             │
    │ • Search orders by number            │
    │ • Tap 3-dot → Delete order           │
    │ ✓ Log: Order Deleted                 │
    │         Order #, amount              │
    └──────────────────────────────────────┘


    ┌──────────────────────────────────────┐
    │ TAB 3: INVENTORY MANAGEMENT          │
    ├──────────────────────────────────────┤
    │ • View current stock levels          │
    │ • See items with low stock (alerts)  │
    │ • Tap item → Adjust quantity         │
    │ • Input change: +5 (restock)         │
    │           OR: -2 (waste/damage)      │
    │ • Select reason: Restock, Waste...   │
    │ ✓ Log: Inventory Adjusted            │
    │         Item, old qty, new qty       │
    │ • View history of adjustments        │
    │ • Search items                       │
    └──────────────────────────────────────┘


    ┌──────────────────────────────────────┐
    │ TAB 4: REPORTS & ANALYTICS           │
    ├──────────────────────────────────────┤
    │ • Daily summary:                     │
    │   - Total sales: $XXX.XX             │
    │   - Orders today: 45                 │
    │   - Items sold: 180                  │
    │   - Cash total: $XXX.XX              │
    │ • Hourly breakdown (chart)           │
    │ • Top 10 popular items               │
    │ • Payment breakdown (cash only)      │
    │ • Inventory status                   │
    │ • All generated from local DB        │
    └──────────────────────────────────────┘


    ┌──────────────────────────────────────┐
    │ TAB 5: ACTIVITY LOG                  │
    ├──────────────────────────────────────┤
    │ • View ALL system activities         │
    │ • Filters: Orders, Payments, Items   │
    │ • Search by name/amount              │
    │ • Timestamps for each activity       │
    │ • Tap activity → view full details   │
    │                                      │
    │ Shows:                               │
    │ ✓ Order Created - Order #145         │
    │ ✓ Payment Processed - $23.50         │
    │ ✓ Order Status Changed - Pending→... │
    │ ✓ Inventory Adjusted - Espresso      │
    │ ✓ Order Deleted - Order #142         │
    │ ✓ Sync Completed - 15 items          │
    │ ✓ Menu Item Updated - Price changed  │
    │                                      │
    │ • Export to CSV (backup/audit)       │
    │ • Clear old logs (>30 days)          │
    └──────────────────────────────────────┘


    BACKGROUND:
    
    ┌──────────────────────────────────────┐
    │ SYNC SERVICE (Always Running)        │
    ├──────────────────────────────────────┤
    │ Monitors: Network connectivity       │
    │                                      │
    │ When online:                         │
    │ 1. Batch all pending operations      │
    │ 2. Send to Supabase                  │
    │ 3. Server validates & processes      │
    │ 4. Receive confirmation              │
    │ 5. Mark as synced in local DB        │
    │ 6. Pull server updates               │
    │ 7. Merge with local data             │
    │ 8. Update UI                         │
    │ ✓ Log: Sync Completed                │
    │         Items synced count           │
    │                                      │
    │ If error:                            │
    │ • Retry with backoff (5s, 30s, etc)  │
    │ ✓ Log: Sync Failed                   │
    │         Error message                │
    └──────────────────────────────────────┘
```

---

## 2. ACTIVITY LOG TRACKING MATRIX

### Complete Activity Log Event Types

```
╔═══════════════════════════════════════════════════════════════════════╗
║                    ACTIVITY LOG TRACKING MATRIX                       ║
╠═══════════════════════════════════════════════════════════════════════╣
║ CATEGORY: ORDER MANAGEMENT                                            ║
╠═══════════════════════════════════════════════════════════════════════╣

EVENT: order_created
├─ Trigger: When new order is created in POS
├─ What's logged:
│  ├─ Order ID
│  ├─ Order number
│  ├─ Items count
│  ├─ Subtotal amount
│  ├─ Tax amount
│  ├─ Total amount
│  └─ Item details (names, quantities)
├─ Entity: Order
├─ Status: completed
└─ Example:
   "Order #145 created with 3 items - Total: $23.50"


EVENT: order_updated
├─ Trigger: When order details are modified
├─ What's logged:
│  ├─ Order ID
│  ├─ Old value (what changed)
│  ├─ New value (to this)
│  ├─ Field changed
│  └─ Timestamp of change
├─ Entity: Order
├─ Status: completed
└─ Example:
   "Order #145: Customer name 'John' → 'Jane'"


EVENT: order_status_changed
├─ Trigger: When order status is updated (pending→preparing→ready...)
├─ What's logged:
│  ├─ Order ID
│  ├─ Order number
│  ├─ Old status (e.g., "pending")
│  ├─ New status (e.g., "preparing")
│  ├─ Timestamp of status change
│  └─ Details: "Order moved from X to Y"
├─ Entity: Order
├─ Status: completed
└─ Example:
   "Order #145: Status pending → preparing"


EVENT: order_completed
├─ Trigger: When order is marked as completed (after payment)
├─ What's logged:
│  ├─ Order ID
│  ├─ Order number
│  ├─ Total amount
│  ├─ Completion timestamp
│  └─ Details: "Order completed and paid"
├─ Entity: Order
├─ Status: completed
└─ Example:
   "Order #145 completed - $23.50 paid"


EVENT: order_cancelled
├─ Trigger: When order is cancelled
├─ What's logged:
│  ├─ Order ID
│  ├─ Order number
│  ├─ Total amount (not collected)
│  ├─ Reason for cancellation
│  └─ Details: "Order cancelled - reason"
├─ Entity: Order
├─ Status: completed
└─ Example:
   "Order #145 cancelled - Customer changed mind"


EVENT: order_deleted
├─ Trigger: When order is permanently deleted
├─ What's logged:
│  ├─ Order ID
│  ├─ Order number
│  ├─ Total amount (lost revenue)
│  ├─ Items in order
│  ├─ Deletion timestamp
│  └─ Details: "Order deleted from system"
├─ Entity: Order
├─ Status: completed
└─ Example:
   "Order #142 DELETED - $18.75 (2 items)"


╠═══════════════════════════════════════════════════════════════════════╣
║ CATEGORY: PAYMENT MANAGEMENT                                          ║
╠═══════════════════════════════════════════════════════════════════════╣

EVENT: payment_processed
├─ Trigger: When cash payment is completed
├─ What's logged:
│  ├─ Payment ID
│  ├─ Order ID
│  ├─ Order number
│  ├─ Order total
│  ├─ Cash tendered (amount customer gave)
│  ├─ Change given (amount returned)
│  ├─ Payment method: "cash"
│  ├─ Status: "completed"
│  └─ Details: "Amount: $X, Tendered: $Y, Change: $Z"
├─ Entity: Payment
├─ Status: completed
└─ Example:
   "Payment for Order #145: $23.50 | Tendered: $30.00 | Change: $6.50"


EVENT: payment_refunded
├─ Trigger: If cash is returned (refund/cancellation)
├─ What's logged:
│  ├─ Original payment ID
│  ├─ Order ID
│  ├─ Refund amount
│  ├─ Reason for refund
│  └─ Details: "Refund processed - reason"
├─ Entity: Payment
├─ Status: completed
└─ Example:
   "Payment refunded for Order #145: $23.50 (customer requested)"


╠═══════════════════════════════════════════════════════════════════════╣
║ CATEGORY: INVENTORY MANAGEMENT                                        ║
╠═══════════════════════════════════════════════════════════════════════╣

EVENT: inventory_adjusted
├─ Trigger: When stock level is manually adjusted
├─ What's logged:
│  ├─ Item ID
│  ├─ Item name
│  ├─ Old quantity
│  ├─ New quantity
│  ├─ Quantity change (±5)
│  ├─ Reason: waste, damage, count correction, etc.
│  └─ Details: "Espresso: 50 → 45 units (waste)"
├─ Entity: Inventory
├─ Status: completed
└─ Example:
   "Espresso: 50 → 48 units (-2) - Damaged"


EVENT: inventory_restocked
├─ Trigger: When new inventory is received
├─ What's logged:
│  ├─ Item ID
│  ├─ Item name
│  ├─ Old quantity
│  ├─ New quantity
│  ├─ Quantity increase (+20)
│  ├─ Restock date
│  └─ Details: "Oat Milk: 10 → 30 units (restocked)"
├─ Entity: Inventory
├─ Status: completed
└─ Example:
   "Oat Milk: 10 → 30 units (+20) - New delivery"


╠═══════════════════════════════════════════════════════════════════════╣
║ CATEGORY: MENU & ITEM MANAGEMENT                                      ║
╠═══════════════════════════════════════════════════════════════════════╣

EVENT: item_added
├─ Trigger: When new menu item is added
├─ What's logged:
│  ├─ Item ID
│  ├─ Item name
│  ├─ Category
│  ├─ Price
│  ├─ Description
│  └─ Details: "New item added - name, price"
├─ Entity: MenuItem
├─ Status: completed
└─ Example:
   "Cappuccino added to menu - $4.50"


EVENT: item_updated
├─ Trigger: When menu item is modified
├─ What's logged:
│  ├─ Item ID
│  ├─ Item name
│  ├─ Field changed (price, name, availability)
│  ├─ Old value
│  ├─ New value
│  └─ Details: "Price: $4.00 → $4.50"
├─ Entity: MenuItem
├─ Status: completed
└─ Example:
   "Cappuccino price updated: $4.00 → $4.50"


EVENT: item_deleted
├─ Trigger: When menu item is removed
├─ What's logged:
│  ├─ Item ID
│  ├─ Item name
│  ├─ Price
│  ├─ Category
│  └─ Details: "Item deleted - name, price"
├─ Entity: MenuItem
├─ Status: completed
└─ Example:
   "Cappuccino DELETED from menu (was $4.50)"


╠═══════════════════════════════════════════════════════════════════════╣
║ CATEGORY: SYSTEM & SYNC                                               ║
╠═══════════════════════════════════════════════════════════════════════╣

EVENT: sync_completed
├─ Trigger: When data is successfully synced to Supabase
├─ What's logged:
│  ├─ Items synced count
│  ├─ Sync timestamp
│  ├─ Data synced: orders, payments, etc.
│  └─ Details: "15 orders synced to cloud"
├─ Entity: System
├─ Status: completed
└─ Example:
   "Sync completed: 15 orders + 3 payments synced"


EVENT: sync_failed
├─ Trigger: When sync attempt fails
├─ What's logged:
│  ├─ Error message
│  ├─ Failure timestamp
│  ├─ Retry count
│  ├─ Next retry time
│  └─ Details: "Error: Network timeout"
├─ Entity: System
├─ Status: failed
└─ Example:
   "Sync failed - Network timeout (Retry in 30s)"


EVENT: menu_synced
├─ Trigger: When menu is updated from server
├─ What's logged:
│  ├─ Items updated count
│  ├─ New items added
│  ├─ Removed items
│  ├─ Price changes
│  └─ Details: "Menu refreshed from server"
├─ Entity: System
├─ Status: completed
└─ Example:
   "Menu synced: 2 items updated, 1 new item"


EVENT: data_exported
├─ Trigger: When activity log is exported
├─ What's logged:
│  ├─ Export date
│  ├─ Records exported count
│  ├─ File location/name
│  └─ Details: "CSV file exported"
├─ Entity: System
├─ Status: completed
└─ Example:
   "Activity log exported: 150 records (activity_log_2024-01-29.csv)"

╚═══════════════════════════════════════════════════════════════════════╝
```

---

## 3. DAILY ACTIVITY LOG EXAMPLE

```
═════════════════════════════════════════════════════════════════════
              CARMEN'S GARDEN CAFE - DAILY ACTIVITY LOG
                      January 29, 2024
═════════════════════════════════════════════════════════════════════

08:15 AM  [ORDER CREATED]      Order #145
          Items: 2 Cappuccino, 1 Espresso
          Total: $13.50
          Status: pending

08:16 AM  [PAYMENT PROCESSED]  Order #145
          Amount: $13.50
          Cash Tendered: $20.00
          Change: $6.50
          Status: completed

08:16 AM  [ORDER STATUS]       Order #145
          Status Changed: pending → completed

08:18 AM  [ORDER CREATED]      Order #146
          Items: 1 Latte, 1 Croissant
          Total: $9.99
          Status: pending

08:20 AM  [ORDER UPDATED]      Order #146
          Customer Name: "Jane" → "Jane Smith"

08:21 AM  [PAYMENT PROCESSED]  Order #146
          Amount: $9.99
          Cash Tendered: $10.00
          Change: $0.01
          Status: completed

08:21 AM  [ORDER STATUS]       Order #146
          Status Changed: pending → completed

09:30 AM  [INVENTORY ADJUSTED] Espresso Beans
          Quantity: 50 → 48 units
          Reason: Waste/Damaged
          Change: -2 units

10:45 AM  [ORDER CREATED]      Order #147
          Items: 3 Cappuccino (Large with Oat Milk)
          Total: $16.50
          Status: pending

10:46 AM  [PAYMENT PROCESSED]  Order #147
          Amount: $16.50
          Cash Tendered: $20.00
          Change: $3.50
          Status: completed

10:46 AM  [ORDER STATUS]       Order #147
          Status Changed: pending → completed

11:15 AM  [INVENTORY RESTOCK]  Oat Milk
          Quantity: 8 → 24 units
          Reason: New delivery
          Change: +16 units

12:30 PM  [ORDER DELETED]      Order #148
          Items: 2 items
          Total: $12.00
          Reason: System cleanup

01:00 PM  [SYNC COMPLETED]     
          Items Synced: 23 orders
          Payments Synced: 23
          Status: Success
          Last Sync Time: 1:00 PM

01:15 PM  [MENU ITEM UPDATED]  Cappuccino
          Price: $4.00 → $4.50
          Change Type: Price increase

02:30 PM  [ORDER CREATED]      Order #149
          Items: 1 Americano, 1 Pastry
          Total: $7.50
          Status: pending

02:31 PM  [PAYMENT PROCESSED]  Order #149
          Amount: $7.50
          Cash Tendered: $10.00
          Change: $2.50
          Status: completed

═════════════════════════════════════════════════════════════════════

DAILY SUMMARY:
─────────────────────────────────────────────────────────────────────
Orders Created:          7
Orders Completed:        6
Orders Deleted:          1
Total Sales:             $69.48
Total Payments:          6
Inventory Adjustments:   2
Menu Changes:            1
Sync Completed:          1
Sync Failures:           0

═════════════════════════════════════════════════════════════════════
```

---

## 4. CASH PAYMENT FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────┐
│               CASH PAYMENT PROCESSING FLOW                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │    Order Total Calculated      │
        │    Subtotal: $20.00            │
        │    Tax (8%): $1.60             │
        │    TOTAL: $21.60               │
        └────────────────┬───────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │   CASH PAYMENT SCREEN DISPLAYED    │
        ├────────────────────────────────────┤
        │ Amount Due: $21.60 (in large text)│
        │                                   │
        │ [Input Field]                      │
        │ Cash Tendered: $ ___              │
        │                                   │
        │ Change Display: $0.00 (dynamic)   │
        │                                   │
        │ Quick Buttons:                     │
        │ [$10] [$20] [$50] [$100] [Exact]  │
        │                                   │
        │ [Complete Payment] (disabled)      │
        └────────┬─────────────────────────┘
                 │
            ┌────┴────┐
            │          │
            ▼          ▼
    [User types]  [User taps quick]
         │        [amount button]
         │              │
         ▼              ▼
    ┌─────────────────────────┐
    │  Calculate Change:      │
    │  Change = Tendered - Due│
    │  $25.00 - $21.60        │
    │  = $3.40                │
    │                         │
    │ Display updated change  │
    │ Enable "Complete Paymt" │
    │ (if change >= 0)        │
    └────────┬────────────────┘
             │
             ▼
    ┌──────────────────────────────────┐
    │  User Taps "Complete Payment"    │
    └────────┬─────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │  CREATE PAYMENT RECORD:              │
    │  ├─ Payment ID (unique)              │
    │  ├─ Order ID (link to order)         │
    │  ├─ Amount: $21.60                   │
    │  ├─ Payment Method: "cash"           │
    │  ├─ Cash Tendered: $25.00            │
    │  ├─ Change Given: $3.40              │
    │  ├─ Status: "completed"              │
    │  └─ Timestamp: now                   │
    └────────┬─────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │  SAVE PAYMENT TO LOCAL DB (SQLite)   │
    └────────┬─────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │  LOG ACTIVITY:                       │
    │  Event: payment_processed            │
    │  Details:                            │
    │  • Amount: $21.60                    │
    │  • Tendered: $25.00                  │
    │  • Change: $3.40                     │
    │  • Order #: 150                      │
    │  • Timestamp: Jan 29, 2:31 PM        │
    └────────┬─────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │  UPDATE ORDER STATUS:                │
    │  Order #150 → Status: "completed"    │
    │  ✓ Mark as paid                      │
    │  ✓ Set completion timestamp          │
    └────────┬─────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │  LOG ACTIVITY:                       │
    │  Event: order_completed              │
    │  Details:                            │
    │  • Order #: 150                      │
    │  • Amount: $21.60                    │
    │  • Status: completed                 │
    │  • Timestamp: Jan 29, 2:31 PM        │
    └────────┬─────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │  ADD TO SYNC QUEUE:                  │
    │  • Payment to sync to Supabase       │
    │  • Order update to sync              │
    │  • Activity log to sync              │
    └────────┬─────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │  SHOW CONFIRMATION DIALOG            │
    ├──────────────────────────────────────┤
    │ ✓ Payment Completed                  │
    │                                      │
    │ Order #150                           │
    │ Amount: $21.60                       │
    │ Tendered: $25.00                     │
    │ Change: $3.40                        │
    │                                      │
    │ [OK]                                 │
    └────────┬─────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │  RETURN TO POS TERMINAL              │
    │  • Clear cart                        │
    │  • Reset form                        │
    │  • Ready for next order              │
    │  • Update reports in background      │
    └──────────────────────────────────────┘
```

---

## 5. ACTIVITY LOG FILTERING & SEARCH

```
ACTIVITY LOG SCREEN - FILTERING EXAMPLE
═════════════════════════════════════════════════════════════════

Search: "cappuccino" [                    ]  [Download icon]

Filters:
[All] [Orders] [Payments] [Inventory] [Menu Items]
  ✓    

═════════════════════════════════════════════════════════════════

RESULTS:

08:15 AM  ✓ Order Created - Cappuccino x2
          Order #145 | Total: $13.50
          
08:20 AM  ✓ Payment Processed - Order #145
          Amount: $13.50 | Cash: $20 | Change: $6.50
          
01:15 PM  ✓ Menu Item Updated - Cappuccino
          Price: $4.00 → $4.50
          
02:30 PM  ✓ Order Created - 1 Cappuccino (Large, Oat Milk)
          Order #149 | Total: $7.50


FILTER BY ENTITY TYPE
═════════════════════════════════════════════════════════════════

Showing: [Orders ✓] [Payments] [Inventory] [Menu]

08:15 AM  ✓ Order Created - Order #145
          Items: 2 Cappuccino, 1 Espresso
          Total: $13.50
          
08:20 AM  ✓ Order Updated - Order #146
          Customer: "Jane" → "Jane Smith"
          
12:30 PM  ✗ Order Deleted - Order #148
          Items: 2 items | Total: $12.00


FILTER BY DATE RANGE
═════════════════════════════════════════════════════════════════

From: [Jan 29, 2024] To: [Jan 29, 2024]

SUMMARY:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Orders Created:        7
Orders Completed:      6
Orders Deleted:        1
Payments Processed:    6
Inventory Adjustments: 2
Menu Updates:          1
Sync Completed:        1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 6. SYNC INTEGRATION WITH ACTIVITY LOG

```
┌──────────────────────────────────────────────────────────┐
│     SYNC SERVICE & ACTIVITY LOG INTEGRATION              │
├──────────────────────────────────────────────────────────┤

1. LOCAL OPERATIONS LOGGED:
   └─ Any action (create/update/delete) instantly logged
   └─ Log entry created in activity_logs table
   └─ Data saved to SQLite
   └─ is_synced = 0 (not yet synced)

2. SYNC INITIATED:
   └─ Detect internet connection
   └─ Gather pending operations from sync_queue
   └─ Gather pending logs from activity_logs
   └─ Batch them together

3. BATCH UPLOAD:
   └─ Send to Supabase
   └─ Server processes
   └─ Returns success/failure

4. SYNC COMPLETED:
   └─ Mark all as synced (is_synced = 1)
   └─ Log "sync_completed" activity
   └─ This log is also synced on next batch
   └─ Merge any server updates

5. AUDIT TRAIL:
   └─ Activity logs create complete audit trail
   └─ Every change logged before sync
   └─ If sync fails, logs remain for retry
   └─ Full history preserved offline
   └─ Cloud backup when online

EXAMPLE SEQUENCE:
─────────────────────────────────────────────────────────────

USER CREATES ORDER (Offline):
├─ Order saved to SQLite
├─ Activity log created: "Order #150 created"
├─ Sync queue entry added
└─ Local state: is_synced = 0

USER PAYS (Offline):
├─ Payment saved to SQLite
├─ Activity log created: "Payment processed"
├─ Order marked completed
├─ Activity log created: "Order status changed"
├─ Sync queue entries added (3 items)
└─ Local state: is_synced = 0 (all 3)

DEVICE COMES ONLINE:
├─ Connectivity detected
├─ SyncService.performFullSync() starts
├─ Collects:
│  ├─ 1 order
│  ├─ 1 payment
│  ├─ 2 activity logs
│  └─ 1 sync queue entry (order update)
├─ Batches all together
└─ POST to Supabase

SUPABASE RECEIVES:
├─ Validates all data
├─ Processes transactions atomically
├─ Returns success: all 5 items processed
└─ Device receives confirmation

DEVICE PROCESSES RESPONSE:
├─ Marks all as synced (is_synced = 1)
├─ Deletes from sync_queue
├─ Creates new activity log:
│  ├─ Event: "sync_completed"
│  ├─ Details: "5 items synced"
│  └─ is_synced = 0 (will sync in next batch)
├─ Updates UI: "✓ Sync complete"
└─ Continues normal operation

NEXT SYNC CYCLE:
└─ The "sync_completed" log is synced
└─ Complete audit trail now in cloud
```

---

## 7. QUICK REFERENCE - WHAT GETS LOGGED

```
═════════════════════════════════════════════════════════════════
                    ACTIVITY LOG QUICK REF
═════════════════════════════════════════════════════════════════

✓ ORDERS:
  • Created (what items, total amount)
  • Updated (what changed, old → new)
  • Status changed (pending → preparing → ready → completed)
  • Completed (order #, amount, payment method)
  • Cancelled (reason, amount lost)
  • Deleted (audit trail - what was deleted)

✓ PAYMENTS:
  • Processed (amount, cash tendered, change given, order #)
  • Refunded (amount, reason, original order #)

✓ INVENTORY:
  • Adjusted (item, old qty, new qty, reason)
  • Restocked (item, increase amount, new total)

✓ MENU:
  • Item added (name, price, category)
  • Item updated (price change, description, etc.)
  • Item deleted (what was removed)

✓ SYSTEM:
  • Sync completed (# items, timestamp)
  • Sync failed (error message, retry count)
  • Menu refreshed (# updates, new items)
  • Data exported (# records, file name)

═════════════════════════════════════════════════════════════════

KEY FIELDS FOR EACH LOG ENTRY:
────────────────────────────────────────────────────────────────
• activity_id (unique UUID)
• timestamp (when it happened)
• activity_type (order_created, payment_processed, etc.)
• entity_type (order, payment, inventory, etc.)
• entity_id (ID of what changed)
• entity_name (human-readable name)
• action (what was done)
• old_value (before change - JSON)
• new_value (after change - JSON)
• details (human-readable summary)
• user_id (who did it - "system" if auto)
• device_id (which device)
• status (completed or failed)
• error_message (if failed)
• is_synced (0 = not yet synced to cloud, 1 = synced)
• created_at (exact timestamp)

═════════════════════════════════════════════════════════════════
```

---

**Status: Complete Visual & Reference Documentation** ✅