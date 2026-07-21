class DatabaseSchema {
  static const List<String> createTablesQueries = [
    '''
    CREATE TABLE IF NOT EXISTS products (
      barcode TEXT PRIMARY KEY,
      name    TEXT NOT NULL,
      price   REAL DEFAULT 0.0,
      stock   INTEGER DEFAULT 0
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS transactions (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at      TEXT NOT NULL,
      total_amount    REAL NOT NULL DEFAULT 0,
      payment_method  TEXT DEFAULT 'tunai',
      amount_paid     REAL DEFAULT 0,
      change_amount   REAL DEFAULT 0,
      status          TEXT DEFAULT 'selesai'
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS transaction_items (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id  INTEGER NOT NULL,
      barcode         TEXT NOT NULL,
      product_name    TEXT NOT NULL,
      price           REAL NOT NULL,
      qty             INTEGER NOT NULL DEFAULT 1,
      subtotal        REAL NOT NULL
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS debt_notes (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      debtor_name   TEXT NOT NULL,
      description   TEXT,
      amount        REAL NOT NULL DEFAULT 0,
      paid          REAL NOT NULL DEFAULT 0,
      created_at    TEXT NOT NULL,
      due_date      TEXT,
      is_settled    INTEGER NOT NULL DEFAULT 0
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS receipt_config (
      id            INTEGER PRIMARY KEY DEFAULT 1,
      store_name    TEXT NOT NULL DEFAULT 'dodolanku',
      store_address TEXT NOT NULL DEFAULT 'Jl. Raya dodolanku No. 1',
      store_phone   TEXT DEFAULT '',
      qris_data     TEXT DEFAULT '',
      header_msg    TEXT,
      footer_msg    TEXT NOT NULL DEFAULT 'Terima Kasih'
    )
    '''
  ];

  static const List<String> createIndexesQueries = [
    "CREATE INDEX IF NOT EXISTS idx_products_barcode ON products (barcode)",
    "CREATE INDEX IF NOT EXISTS idx_products_name ON products (name)",
    "CREATE INDEX IF NOT EXISTS idx_transaction_items_tx ON transaction_items (transaction_id)",
    "CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (created_at)",
    "CREATE INDEX IF NOT EXISTS idx_debt_notes_debtor ON debt_notes (debtor_name)"
  ];
}
